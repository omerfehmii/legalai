import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../models/chat_message.dart'; // Adjust path if needed
import '../../../models/document_generation_status.dart'; // Adjust path if needed
import '../services/generator_service.dart'; // We might need a dedicated service or reuse chat service

part 'generator_providers.g.dart';

// State for the Generator
@riverpod
class GeneratorNotifier extends _$GeneratorNotifier {
  // Option 1: Reuse ChatService if processTurn handles both modes
  late final ChatService _chatService;
  // Option 2: Create a dedicated GeneratorService
  // late final GeneratorService _generatorService;
  final _uuid = const Uuid();

  @override
  GeneratorState build() {
    _chatService = ref.watch(chatServiceProvider); // Assuming reuse
    // _generatorService = ref.watch(generatorServiceProvider); // If dedicated
    return GeneratorState();
  }

  Future<void> startDocumentFlow(String documentType) async {
    // Initial message to backend to start the generation process
    final initialMessage = "Bir '$documentType' oluşturmak istiyorum.";
    state = GeneratorState(); // Reset state for new document
    await processGeneratorMessage(initialMessage, isInitialization: true);
  }

  Future<void> processGeneratorMessage(String text, {bool isInitialization = false}) async {
    if (state.status == DocumentGenerationStatus.loading && !isInitialization) return;

    ChatMessage? userMessage;
    if (!isInitialization) {
      userMessage = ChatMessage(
        id: _uuid.v4(),
        chatId: state.currentChatId,
        text: text,
        sender: Sender.user,
        timestamp: DateTime.now(),
      );
    }

    // Add user message (if any) and set loading state
    state = state.copyWith(
      messages: userMessage != null ? [...state.messages, userMessage] : state.messages,
      status: DocumentGenerationStatus.loading,
      errorMessage: null,
    );

    try {
      // Use the same processTurn endpoint, but with mode: 'generator'
      final response = await _chatService.processTurn(
        message: text,
        chatId: state.currentChatId, // May be null initially
        status: isInitialization ? DocumentGenerationStatus.idle : state.status,
        mode: 'generator', // <<< Specify the mode here
        collectedData: state.collectedData, // Send current data
        documentType: state.documentType ?? (isInitialization ? text.split("'")[1] : null), // Send doc type
      );

      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        chatId: response.chatId,
        text: response.responseText,
        sender: Sender.ai,
        timestamp: DateTime.now(),
        isConfirmationRequest: response.isConfirmationRequest,
        pdfUrl: response.pdfUrl,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        status: response.newStatus,
        collectedData: response.collectedData ?? state.collectedData,
        currentChatId: response.chatId, // Important to store the chat ID from the first response
        documentType: state.documentType ?? response.documentType, // Store doc type if returned
        errorMessage: null,
      );
    } catch (e) {
      print('Error processing generator message: $e');
      final errorMessage = ChatMessage(
          id: _uuid.v4(),
          chatId: state.currentChatId,
          text: "Belge oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.",
          sender: Sender.ai,
          timestamp: DateTime.now(),
          isError: true);
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        status: DocumentGenerationStatus.idle, // Reset to idle on error
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> confirmCollectedData() async {
    if (state.status != DocumentGenerationStatus.awaitingConfirmation) return;

    state = state.copyWith(status: DocumentGenerationStatus.loading);

    try {
      // Re-use processTurn, sending confirmation
      final response = await _chatService.processTurn(
        message: "evet", // User confirms
        chatId: state.currentChatId!, 
        status: state.status,
        mode: 'generator',
        collectedData: state.collectedData,
        documentType: state.documentType,
      );

       final aiMessage = ChatMessage(
        id: _uuid.v4(),
        chatId: response.chatId,
        text: response.responseText, // Should be the "generating document" message
        sender: Sender.ai,
        timestamp: DateTime.now(),
        isConfirmationRequest: response.isConfirmationRequest,
        pdfUrl: response.pdfUrl, // PDF URL should be here!
      );

      // Update state with the final message and PDF URL
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        status: response.newStatus, // Should be idle or completed
        errorMessage: null,
      );

    } catch (e) {
       print('Error confirming data: $e');
       final errorMessage = ChatMessage(
          id: _uuid.v4(),
          chatId: state.currentChatId,
          text: "Belge onaylanırken bir hata oluştu.",
          sender: Sender.ai,
          timestamp: DateTime.now(),
          isError: true);
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        status: DocumentGenerationStatus.awaitingConfirmation, // Stay in confirmation state
        errorMessage: e.toString(),
      );
    }
  }

  void resetGenerator() {
     state = GeneratorState();
  }

}

// State object for Generator
class GeneratorState {
  final List<ChatMessage> messages;
  final DocumentGenerationStatus status;
  final Map<String, dynamic> collectedData;
  final String? errorMessage;
  final String? currentChatId; // Can be null initially
  final String? documentType; // Track the type being generated
  final bool isAiAsking; // Derived state

  GeneratorState({
    this.messages = const [],
    this.status = DocumentGenerationStatus.idle,
    this.collectedData = const {},
    this.errorMessage,
    this.currentChatId,
    this.documentType,
  }) : isAiAsking = status == DocumentGenerationStatus.collectingInfo || 
                     status == DocumentGenerationStatus.awaitingConfirmation;

  GeneratorState copyWith({
    List<ChatMessage>? messages,
    DocumentGenerationStatus? status,
    Map<String, dynamic>? collectedData,
    String? errorMessage,
    String? currentChatId,
    String? documentType,
  }) {
    return GeneratorState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      collectedData: collectedData ?? this.collectedData,
      errorMessage: errorMessage ?? this.errorMessage,
      currentChatId: currentChatId ?? this.currentChatId,
      documentType: documentType ?? this.documentType,
    );
  }
}


// Define the provider itself using the generator
@riverpod
GeneratorNotifier generatorNotifier(GeneratorNotifierRef ref) {
  // We need access to ChatService, ensure it's provided
  // final chatService = ref.watch(chatServiceProvider);
  return GeneratorNotifier(/* Pass dependencies if needed */);
}

// Assuming ChatService is defined elsewhere and provided
// Example provider for ChatService (adjust path as needed)
// import '../services/chat_service.dart';
// final chatServiceProvider = Provider<ChatService>((ref) => ChatService(ref)); 