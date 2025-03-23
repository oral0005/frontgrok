import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../widgets/appinio_animated_toggle_tab.dart'; // Import the local widget

class CreateFormScreen extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const CreateFormScreen({super.key, this.onPostCreated});

  @override
  _CreateFormScreenState createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  final _fromController = TextEditingController();
  final _routeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _documentsController = TextEditingController();
  DateTime _departureTime = DateTime.now();
  final ApiService _apiService = ApiService();
  int _selectedTabIndex = 0;
  bool _isLoading = false;

  final Color kDarkBlueColor = const Color(0xFF053149);
  final BoxShadow kDefaultBoxshadow = const BoxShadow(
    color: Color(0xFFDFDFDF),
    spreadRadius: 1,
    blurRadius: 10,
    offset: Offset(2, 2),
  );

  Future<void> _createPost() async {
    if (_routeController.text.isEmpty || _priceController.text.isEmpty) {
      _showSnackBar('Please fill in required fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_selectedTabIndex == 0) {
        // Create Sender Post ("Отправить посылку")
        await _apiService.createSenderPost(
          _routeController.text,
          _departureTime,
          double.tryParse(_priceController.text) ?? 0.0,
          _descriptionController.text,
        );
      } else {
        // Create Courier Post ("Доставить посылку")
        await _apiService.createCourierPost(
          _routeController.text,
          _departureTime,
          double.tryParse(_priceController.text) ?? 0.0,
          _descriptionController.text,
        );
      }
      widget.onPostCreated?.call();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _fromController.dispose();
    _routeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _documentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Form')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AppinioAnimatedToggleTab(
                    duration: const Duration(milliseconds: 150),
                    offset: 0,
                    callback: (int index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    tabTexts: const [
                      'Отправить посылку',
                      'Доставить посылку',
                    ],
                    height: 40,
                    width: MediaQuery.of(context).size.width - 32, // Adjust for padding
                    boxDecoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        kDefaultBoxshadow,
                      ],
                    ),
                    animatedBoxDecoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFc3d2db).withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(2, 2),
                        ),
                      ],
                      color: kDarkBlueColor,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5),
                      ),
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    activeStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    inactiveStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(label: 'Откуда', controller: _fromController),
                  const SizedBox(height: 20),
                  CustomTextField(label: 'Куда', controller: _routeController),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null && mounted) {
                        setState(() => _departureTime = pickedDate);
                      }
                    },
                    child: Text('Крайняя дата отправки: ${_departureTime.toString().split(' ')[0]}'),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(label: 'Описание посылки', controller: _descriptionController),
                  const SizedBox(height: 20),
                  CustomTextField(label: 'Документы', controller: _documentsController),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: _selectedTabIndex == 0 ? 'Цена за посылку' : 'Цена за доставку',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(text: 'Добавить фото', onPressed: () {}, color: Colors.grey),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Сохранить',
                    onPressed: _isLoading ? null : _createPost,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}