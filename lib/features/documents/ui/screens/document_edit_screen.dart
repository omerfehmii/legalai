import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:legalai/core/theme/app_theme.dart';
import 'package:legalai/features/documents/data/models/saved_document.dart';
import 'package:legalai/features/documents/services/document_generation_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Belge düzenleme ekranı
class DocumentEditScreen extends ConsumerStatefulWidget {
  final SavedDocument document;
  
  const DocumentEditScreen({
    Key? key,
    required this.document,
  }) : super(key: key);
  
  @override
  ConsumerState<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends ConsumerState<DocumentEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  late List<String> _selectedTags;
  late DocumentStatus _selectedStatus;
  late DateTime? _selectedExpiryDate;
  late bool _isFavorite;
  bool _isModified = false;
  bool _isLoading = false;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  
  // Kategoriler listesi
  final List<String> _categories = [
    'Genel',
    'Sözleşmeler',
    'Dilekçeler',
    'Raporlar',
    'Ticari',
    'Kişisel',
    'Diğer',
  ];
  
  // Etiketler listesi
  final List<String> _availableTags = [
    'Acil',
    'Tamamlandı',
    'Taslak',
    'Beklemede',
    'Önemli',
    'İşe İlişkin',
    'Aile',
    'Finans',
    'Konut',
    'Sağlık',
    'Sigorta',
    'Banka',
    'İcra',
    'Ceza',
    'Vergi',
  ];
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _notesController = TextEditingController(text: widget.document.notes ?? '');
    _selectedCategory = widget.document.category;
    _selectedTags = List<String>.from(widget.document.tags);
    _selectedStatus = widget.document.status;
    _selectedExpiryDate = widget.document.expiryDate;
    _isFavorite = widget.document.isFavorite ?? false;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _updateDocument() async {
    if (!_isModified) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Belge nesnesini güncelle
      widget.document.update(
        title: _titleController.text,
        notes: _notesController.text,
        category: _selectedCategory,
        tags: _selectedTags,
        status: _selectedStatus,
        expiryDate: _selectedExpiryDate,
        isFavorite: _isFavorite,
      );
      
      // Belgeyi kaydet
      final docService = ref.read(documentGenerationServiceProvider);
      await docService.updateDocument(widget.document);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belge başarıyla güncellendi')),
      );
      
      setState(() {
        _isModified = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belge güncellenirken hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _shareDocument() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final docService = ref.read(documentGenerationServiceProvider);
      await docService.shareDocument(widget.document);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belge paylaşılırken hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _exportDocument() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final docService = ref.read(documentGenerationServiceProvider);
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final exportPath = await docService.exportDocument(widget.document, directory);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belge dışa aktarıldı: $exportPath'),
          action: SnackBarAction(
            label: 'PAYLAŞ',
            onPressed: () {
              Share.shareXFiles([XFile(exportPath)]);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belge dışa aktarılırken hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _createNewVersion() async {
    final docService = ref.read(documentGenerationServiceProvider);
    
    // Eski belgeyi tamamlanmış olarak işaretle
    widget.document.update(status: DocumentStatus.archived);
    await docService.updateDocument(widget.document);
    
    // Yeni versiyon oluştur
    final newVersion = widget.document.createNewVersion(
      status: DocumentStatus.draft,
    );
    
    // Yeni versiyonu kaydet
    await docService.updateDocument(newVersion);
    
    // Yeni versiyon ekranına git
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DocumentEditScreen(document: newVersion),
        ),
      );
    }
  }
  
  bool _hasValidPdf() {
    return widget.document.pdfPath != null && 
           File(widget.document.pdfPath!).existsSync();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Belge Düzenle', style: AppTheme.headingSmall(context)),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Yeni versiyon oluştur
          IconButton(
            icon: const Icon(Icons.file_copy_outlined),
            tooltip: 'Yeni Versiyon Oluştur',
            onPressed: _createNewVersion,
          ),
          
          // Paylaş butonu
          if (_hasValidPdf())
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Paylaş',
              onPressed: _shareDocument,
            ),
          
          // Dışa aktar butonu
          if (_hasValidPdf())
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Dışa Aktar',
              onPressed: _exportDocument,
            ),
            
          // Kaydet butonu
          IconButton(
            icon: Icon(
              Icons.save_outlined,
              color: _isModified ? AppTheme.secondaryColor : null,
            ),
            tooltip: 'Değişiklikleri Kaydet',
            onPressed: _isModified ? _updateDocument : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }
  
  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // Belge bilgileri ve PDF/içerik görüntüleyici
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).cardColor,
                  child: TabBar(
                    tabs: const [
                      Tab(text: 'BİLGİLER'),
                      Tab(text: 'PDF'),
                      Tab(text: 'İÇERİK'),
                    ],
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.mutedTextColor,
                    indicatorColor: AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildInfoTab(context),
                      _buildPdfTab(context),
                      _buildContentTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Belge Başlığı',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _isModified = true;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Belge Türü ve Durum
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belge Türü',
                        style: AppTheme.bodyMedium(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.document.documentType,
                        style: AppTheme.bodyLarge(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Durum',
                        style: AppTheme.bodyMedium(context),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<DocumentStatus>(
                        value: _selectedStatus,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        underline: Container(height: 0),
                        onChanged: (DocumentStatus? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedStatus = newValue;
                              _isModified = true;
                            });
                          }
                        },
                        items: DocumentStatus.values.map((DocumentStatus status) {
                          return DropdownMenuItem<DocumentStatus>(
                            value: status,
                            child: Text(_getStatusText(status)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Kategori seçimi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori',
                  style: AppTheme.bodyMedium(context),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: Container(height: 0),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                        _isModified = true;
                      });
                    }
                  },
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Etiketler
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Etiketler',
                  style: AppTheme.bodyMedium(context),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                          _isModified = true;
                        });
                      },
                      backgroundColor: Theme.of(context).cardColor,
                      selectedColor: AppTheme.secondaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.secondaryColor,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Son geçerlilik tarihi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Son Geçerlilik Tarihi',
                      style: AppTheme.bodyMedium(context),
                    ),
                    Switch(
                      value: _selectedExpiryDate != null,
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            // Bugünden 1 yıl sonra varsayılan tarih
                            _selectedExpiryDate = DateTime.now().add(const Duration(days: 365));
                          } else {
                            _selectedExpiryDate = null;
                          }
                          _isModified = true;
                        });
                      },
                      activeColor: AppTheme.secondaryColor,
                    ),
                  ],
                ),
                if (_selectedExpiryDate != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedExpiryDate!,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedExpiryDate = picked;
                          _isModified = true;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd.MM.yyyy').format(_selectedExpiryDate!),
                            style: AppTheme.bodyLarge(context),
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Favorilere ekle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Favorilere Ekle',
                  style: AppTheme.bodyMedium(context),
                ),
                Switch(
                  value: _isFavorite,
                  onChanged: (value) {
                    setState(() {
                      _isFavorite = value;
                      _isModified = true;
                    });
                  },
                  activeColor: AppTheme.secondaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Notlar
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notlar',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            onChanged: (value) {
              setState(() {
                _isModified = true;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Versiyon bilgisi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Versiyon',
                      style: AppTheme.bodyMedium(context),
                    ),
                    Text(
                      'v${widget.document.version}',
                      style: AppTheme.bodyLarge(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Oluşturulma Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(widget.document.createdAt)}',
                  style: AppTheme.caption(context),
                ),
                const SizedBox(height: 4),
                Text(
                  'Son Güncelleme: ${DateFormat('dd.MM.yyyy HH:mm').format(widget.document.updatedAt)}',
                  style: AppTheme.caption(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPdfTab(BuildContext context) {
    if (!_hasValidPdf()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'PDF dosyası bulunamadı',
              style: AppTheme.bodyLarge(context),
            ),
          ],
        ),
      );
    }
    
    return Container(
      color: Colors.grey.shade100,
      child: SfPdfViewer.file(
        File(widget.document.pdfPath!),
        key: _pdfViewerKey,
      ),
    );
  }
  
  Widget _buildContentTab(BuildContext context) {
    if (widget.document.generatedContent == null || widget.document.generatedContent!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.text_snippet, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'İçerik bulunamadı',
              style: AppTheme.bodyLarge(context),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.document.generatedContent!,
        style: AppTheme.bodyLarge(context),
      ),
    );
  }
  
  String _getStatusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.draft:
        return 'Taslak';
      case DocumentStatus.completed:
        return 'Tamamlandı';
      case DocumentStatus.signed:
        return 'İmzalandı';
      case DocumentStatus.submitted:
        return 'Teslim Edildi';
      case DocumentStatus.expired:
        return 'Süresi Geçti';
      case DocumentStatus.archived:
        return 'Arşivlendi';
      default:
        return 'Bilinmiyor';
    }
  }
} 