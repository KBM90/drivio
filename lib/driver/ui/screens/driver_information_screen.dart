import 'dart:io';
import 'package:drivio_app/common/models/user.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DriverInformationScreen extends StatefulWidget {
  const DriverInformationScreen({super.key});

  @override
  State<DriverInformationScreen> createState() =>
      _DriverInformationScreenState();
}

class _DriverInformationScreenState extends State<DriverInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _rangeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Driver? _driver;
  User? _user;
  XFile? _profileImage;
  String? _currentProfileImageUrl;

  // Gender
  String? _selectedGender;
  final List<String> _genders = ['male', 'female'];

  // Preferences
  bool _smoking = false;
  List<String> _selectedLanguages = [];
  List<String> _selectedMusicStyles = [];

  final List<String> _availableLanguages = [
    'Arabic',
    'English',
    'Tamazight',
    'French',
    'Spanish',
    'German',
    'Italian',
    'Chinese',
    'Japanese',
    'Portuguese',
    'Russian',
  ];

  final List<String> _availableMusicStyles = [
    'Pop',
    'Rock',
    'Jazz',
    'Classical',
    'Hip Hop',
    'R&B',
    'Rai',
    'Soul',
    'Electronic',
    'Country',
    'Reggae',
    'Blues',
    'Rap',
  ];

  // Driver documents
  final List<DriverDocument> _documents = [];
  bool _isLoadingDocuments = false;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }

  Future<void> _loadDriverInfo() async {
    try {
      setState(() => _isLoading = true);

      // Fetch driver directly from service
      _driver = await DriverService.getDriver();
      _user = _driver?.user;

      debugPrint('🔍 Driver loaded: ${_driver?.id}');
      debugPrint('🔍 User loaded: ${_user?.name}');

      if (_user != null) {
        _nameController.text = _user!.name;
        _phoneController.text = _user!.phone ?? '';
        _emailController.text = _user!.email;
        _selectedGender = _user!.sexe;
        _currentProfileImageUrl = _user!.profileImagePath;

        debugPrint('✅ Name field set to: ${_nameController.text}');
      } else {
        debugPrint('⚠️ User is null!');
      }

      if (_driver != null) {
        _rangeController.text = _driver!.range?.toString() ?? '5.0';

        // Load preferences from metadata
        final prefs = _driver!.preferences;
        if (prefs != null) {
          _smoking = prefs['smoking'] == true;
          _selectedLanguages = List<String>.from(prefs['languages'] ?? []);
          _selectedMusicStyles = List<String>.from(prefs['music_styles'] ?? []);
        }
      }

      // Load driver documents
      await _loadDocuments();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading driver info: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDocuments() async {
    // TODO: Implement loading driver documents from database
    setState(() => _isLoadingDocuments = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoadingDocuments = false);
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = image);
    }
  }

  Future<void> _saveDriverInfo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      // Upload profile image if changed
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await DriverService.uploadProfileImage(
          _profileImage!.path,
        );
      }

      // Prepare preferences metadata
      final preferences = {
        'smoking': _smoking,
        'languages': _selectedLanguages,
        'music_styles': _selectedMusicStyles,
      };

      // Update user information (users table)
      await DriverService.updateUserInfo(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender,
        profileImagePath: profileImageUrl,
      );

      // Update driver information (drivers table)
      final range = double.tryParse(_rangeController.text);
      await DriverService.updateDriverInfo(
        range: range,
        preferences: preferences,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Information saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Update local state with new profile image URL
        if (profileImageUrl != null) {
          setState(() {
            _currentProfileImageUrl = profileImageUrl;
            _profileImage = null;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving driver info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving information: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showAddLanguageDialog() {
    final availableToAdd =
        _availableLanguages
            .where((lang) => !_selectedLanguages.contains(lang))
            .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All languages already selected')),
      );
      return;
    }

    String? selectedLanguage;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Language'),
            content: DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Select Language',
                border: OutlineInputBorder(),
              ),
              items:
                  availableToAdd.map((lang) {
                    return DropdownMenuItem(value: lang, child: Text(lang));
                  }).toList(),
              onChanged: (value) => selectedLanguage = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedLanguage != null) {
                    setState(() => _selectedLanguages.add(selectedLanguage!));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showAddMusicStyleDialog() {
    final availableToAdd =
        _availableMusicStyles
            .where((style) => !_selectedMusicStyles.contains(style))
            .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All music styles already selected')),
      );
      return;
    }

    String? selectedStyle;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Music Style'),
            content: DropdownButtonFormField<String>(
              value: selectedStyle,
              decoration: const InputDecoration(
                labelText: 'Select Music Style',
                border: OutlineInputBorder(),
              ),
              items:
                  availableToAdd.map((style) {
                    return DropdownMenuItem(value: style, child: Text(style));
                  }).toList(),
              onChanged: (value) => selectedStyle = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedStyle != null) {
                    setState(() => _selectedMusicStyles.add(selectedStyle!));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _showAddDocumentDialog() async {
    String? selectedDocType;
    DateTime? expiryDate;
    XFile? docImage;
    bool isUploading = false;
    final documentNumberController = TextEditingController();

    final documentTypes = ['Driving License', 'ID Card', 'Passport', 'Other'];

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Add Document'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedDocType,
                        decoration: const InputDecoration(
                          labelText: 'Document Type',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            documentTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedDocType = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: documentNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Document Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          expiryDate == null
                              ? 'Select Expiry Date'
                              : 'Expires: ${expiryDate!.toLocal().toString().split(' ')[0]}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (date != null) {
                            setDialogState(() => expiryDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setDialogState(() => docImage = image);
                          }
                        },
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              docImage != null
                                  ? Image.file(
                                    File(docImage!.path),
                                    fit: BoxFit.cover,
                                  )
                                  : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload_file),
                                      Text('Tap to upload image'),
                                    ],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isUploading
                            ? null
                            : () async {
                              if (selectedDocType == null ||
                                  documentNumberController.text.isEmpty ||
                                  expiryDate == null ||
                                  docImage == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill all fields'),
                                  ),
                                );
                                return;
                              }

                              try {
                                setDialogState(() => isUploading = true);
                                // TODO: Implement document upload
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  _loadDocuments();
                                }
                              } catch (e) {
                                debugPrint('❌ Error adding document: $e');
                                setDialogState(() => isUploading = false);
                              }
                            },
                    child:
                        isUploading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                            : const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );

    // Dispose controller after dialog closes
    documentNumberController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Information'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveDriverInfo,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  _profileImage != null
                                      ? FileImage(File(_profileImage!.path))
                                      : _currentProfileImageUrl != null
                                      ? NetworkImage(_currentProfileImageUrl!)
                                      : null,
                              child:
                                  _profileImage == null &&
                                          _currentProfileImageUrl == null
                                      ? const Icon(Icons.person, size: 60)
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _pickProfileImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Personal Information Section
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,

                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.wc),
                        ),
                        items:
                            _genders.map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                // Capitalize first letter for display
                                child: Text(
                                  gender[0].toUpperCase() + gender.substring(1),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Range
                      TextFormField(
                        controller: _rangeController,
                        decoration: const InputDecoration(
                          labelText: 'Range (km)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.radar),
                          suffixText: 'km',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter range';
                          }
                          final range = double.tryParse(value);
                          if (range == null || range <= 0) {
                            return 'Please enter a valid range';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Preferences Section
                      const Text(
                        'Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Smoking
                      Card(
                        child: SwitchListTile(
                          title: const Text('Smoking'),
                          subtitle: Text(_smoking ? 'Yes' : 'No'),
                          value: _smoking,
                          onChanged: (value) {
                            setState(() => _smoking = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Languages
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Languages',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle),
                                    onPressed: _showAddLanguageDialog,
                                  ),
                                ],
                              ),
                              if (_selectedLanguages.isEmpty)
                                const Text(
                                  'No languages selected',
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  children:
                                      _selectedLanguages.map((lang) {
                                        return Chip(
                                          label: Text(lang),
                                          onDeleted: () {
                                            setState(
                                              () => _selectedLanguages.remove(
                                                lang,
                                              ),
                                            );
                                          },
                                        );
                                      }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Music Styles
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Music Styles',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle),
                                    onPressed: _showAddMusicStyleDialog,
                                  ),
                                ],
                              ),
                              if (_selectedMusicStyles.isEmpty)
                                const Text(
                                  'No music styles selected',
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  children:
                                      _selectedMusicStyles.map((style) {
                                        return Chip(
                                          label: Text(style),
                                          onDeleted: () {
                                            setState(
                                              () => _selectedMusicStyles.remove(
                                                style,
                                              ),
                                            );
                                          },
                                        );
                                      }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Documents Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Documents',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: _showAddDocumentDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _isLoadingDocuments
                          ? const Center(child: CircularProgressIndicator())
                          : _documents.isEmpty
                          ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'No documents added yet.\nTap + to add your driving license and other documents.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _documents.length,
                            itemBuilder: (context, index) {
                              final doc = _documents[index];
                              final isExpired = doc.expiryDate.isBefore(
                                DateTime.now(),
                              );

                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.description),
                                  title: Text(doc.type),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Number: ${doc.number}'),
                                      Text(
                                        'Expires: ${doc.expiryDate.toLocal().toString().split(' ')[0]}',
                                        style: TextStyle(
                                          color:
                                              isExpired
                                                  ? Colors.red
                                                  : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      // TODO: Implement delete
                                      _loadDocuments();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _rangeController.dispose();
    super.dispose();
  }
}

// Temporary model for driver documents
class DriverDocument {
  final String type;
  final String number;
  final DateTime expiryDate;

  DriverDocument({
    required this.type,
    required this.number,
    required this.expiryDate,
  });
}
