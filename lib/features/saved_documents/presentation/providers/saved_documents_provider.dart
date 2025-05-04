import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai/features/saved_documents/data/models/saved_document.dart';
import 'package:legalai/features/advisor/services/advisor_service.dart';
import 'package:legalai/dependency_injection.dart';

// State class to hold the list of saved documents and loading status
class SavedDocumentsState {
  final List<SavedDocument> documents;
  final bool isLoading;

  SavedDocumentsState({this.documents = const [], this.isLoading = false});

  SavedDocumentsState copyWith({
    List<SavedDocument>? documents,
    bool? isLoading,
  }) {
    return SavedDocumentsState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Notifier class to manage the state
class SavedDocumentsNotifier extends StateNotifier<SavedDocumentsState> {
  final AdvisorService _advisorService;

  SavedDocumentsNotifier(this._advisorService) : super(SavedDocumentsState()) {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    state = state.copyWith(isLoading: true);
    try {
      final docs = await _advisorService.loadSavedDocuments();
      // Sort by timestamp descending (newest first)
      docs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(documents: docs, isLoading: false);
    } catch (e) {
      // Handle error appropriately, maybe set an error state
      print('Error loading saved documents: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _advisorService.deleteSavedDocument(documentId);
      // Reload documents after deletion
      await loadDocuments();
    } catch (e) {
      // Handle error appropriately
      print('Error deleting document: $e');
    }
  }
}

// Riverpod provider
final savedDocumentsProvider = StateNotifierProvider<SavedDocumentsNotifier, SavedDocumentsState>((ref) {
  final advisorService = ref.watch(advisorServiceProvider);
  return SavedDocumentsNotifier(advisorService);
}); 