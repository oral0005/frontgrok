import 'package:flutter/material.dart';
import 'package:frontgrok/pages/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../widgets/appinio_animated_toggle_tab.dart';
import 'my_posts_screen.dart';

class CreateFormScreen extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const CreateFormScreen({super.key, this.onPostCreated});

  @override
  _CreateFormScreenState createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _departureTime = DateTime.now();
  final ApiService _apiService = ApiService();
  int _selectedTabIndex = 0;
  bool _isLoading = false;

  // Список городов Казахстана с населением более 50,000
  final List<String> _kazakhstanCities = [
    'Almaty',
    'Astana (Nur-Sultan)',
    'Shymkent',
    'Karaganda (Qaraghandy)',
    'Aktobe',
    'Taraz',
    'Pavlodar',
    'Ust-Kamenogorsk (Oskemen)',
    'Semey (Semipalatinsk)',
    'Atyrau',
    'Kostanay (Qostanay)',
    'Kyzylorda',
    'Uralsk (Oral)',
    'Petropavl',
    'Aktau',
    'Temirtau',
    'Turkestan',
    'Taldykorgan',
    'Ekibastuz',
    'Rudny',
    'Zhanaozen',
    'Zhezkazgan (Jezkazgan)',
    'Kentau',
    'Balkhash',
    'Satbayev (Satpaev)',
    'Kokshetau',
    'Saran',
    'Shakhtinsk',
    'Ridder',
    'Arkalyk',
    'Lisakovsk',
    'Aral',
    'Zhetisay',
    'Saryagash',
    'Aksu',
    'Stepnogorsk',
    'Kapchagay (Kapshagay)',
  ];

  String? _selectedFrom; // Переменная для хранения выбранного "From"
  String? _selectedTo;   // Переменная для хранения выбранного "To"

  final Color kRedColor = Colors.red;
  final BoxShadow kDefaultBoxshadow = const BoxShadow(
    color: Color(0xFFDFDFDF),
    spreadRadius: 1,
    blurRadius: 10,
    offset: Offset(2, 2),
  );

  Future<void> _createPost() async {
    if (_selectedFrom == null || _selectedTo == null || _priceController.text.isEmpty) {
      _showSnackBar('Please select From, To, and fill in the price');
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Starting post creation process...');
      final double price = double.tryParse(_priceController.text) ?? 0.0;

      if (_selectedTabIndex == 0) {
        print('Creating courier post: from=$_selectedFrom, '
            'to=$_selectedTo, '
            'departureTime=${_departureTime.toIso8601String()}, '
            'price=$price, description=${_descriptionController.text}');
        await _apiService.createCourierPost(
          _selectedFrom!,
          _selectedTo!,
          _departureTime,
          price,
          _descriptionController.text,
        ).timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception('Request timed out after 10 seconds');
        });
        print('Courier post created successfully');
      } else {
        print('Creating sender post: from=$_selectedFrom, '
            'to=$_selectedTo, '
            'sendTime=${_departureTime.toIso8601String()}, '
            'price=$price, description=${_descriptionController.text}');
        await _apiService.createSenderPost(
          _selectedFrom!,
          _selectedTo!,
          _departureTime,
          price,
          _descriptionController.text,
        ).timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception('Request timed out after 10 seconds');
        });
        print('Sender post created successfully');
      }

      print('Calling onPostCreated callback');
      widget.onPostCreated?.call();

      if (mounted) {
        print('Navigating to MyPostsScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        print('Widget not mounted, skipping navigation');
      }
    } catch (e) {
      print('Error during post creation: $e');
      if (mounted) {
        _showSnackBar('Failed to create post: $e');
      }
    } finally {
      if (mounted) {
        print('Setting isLoading to false');
        setState(() => _isLoading = false);
      } else {
        print('Widget not mounted, skipping setState');
      }
    }
  }

  void _showSnackBar(String message) {
    print('Showing SnackBar: $message');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && mounted) {
      print('Selected date: ${pickedDate.toIso8601String()}');
      setState(() => _departureTime = pickedDate);
    }
  }

  @override
  void dispose() {
    print('Disposing controllers');
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building CreateFormScreen');
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
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
                      print('Tab switched to index: $index');
                      setState(() => _selectedTabIndex = index);
                    },
                    tabTexts: const ['Courier Posts', 'Sender Posts'],
                    height: 40,
                    width: MediaQuery.of(context).size.width - 32,
                    boxDecoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [kDefaultBoxshadow],
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
                      color: kRedColor,
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      border: Border.all(color: Colors.grey, width: 1),
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
                  // Выпадающий список для "From" с открытием вниз
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    value: _selectedFrom,
                    items: _kazakhstanCities.map((city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFrom = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a city' : null,
                    menuMaxHeight: 200, // Ограничение высоты списка
                    isExpanded: true, // Растягивает поле на всю ширину
                    dropdownColor: Colors.white, // Цвет фона списка
                    style: const TextStyle(color: Colors.black), // Стиль текста
                  ),
                  const SizedBox(height: 20),
                  // Выпадающий список для "To" с открытием вниз
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    value: _selectedTo,
                    items: _kazakhstanCities.map((city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTo = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a city' : null,
                    menuMaxHeight: 200, // Ограничение высоты списка
                    isExpanded: true, // Растягивает поле на всю ширину
                    dropdownColor: Colors.white, // Цвет фона списка
                    style: const TextStyle(color: Colors.black), // Стиль текста
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Departure Date',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          Text(
                            _departureTime.toString().split(' ')[0],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(label: 'Description', controller: _descriptionController),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: _selectedTabIndex == 0 ? 'Delivery Price' : 'Parcel Price',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Save',
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