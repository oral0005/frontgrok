import 'package:flutter/material.dart';
import 'package:frontgrok/pages/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../widgets/appinio_animated_toggle_tab.dart';
import 'my_posts_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/user.dart';

class CreateFormScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback? onPostCreated;

  const CreateFormScreen({super.key, required this.currentUser, this.onPostCreated});

  @override
  _CreateFormScreenState createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _sendTime = DateTime.now();
  final ApiService _apiService = ApiService();
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  double? _recommendedPrice;
  bool _isFetchingPrice = false;

  final List<String> _kazakhstanCities = [
    'Almaty',
    'Astana',
    'Shymkent',
    'Karaganda',
    'Aktobe',
    'Taraz',
    'Pavlodar',
    'Ust-Kamenogorsk',
    'Semey',
    'Atyrau',
    'Kostanay',
    'Kyzylorda',
    'Uralsk',
    'Petropavl',
    'Aktau',
    'Temirtau',
    'Turkestan',
    'Taldykorgan',
    'Ekibastuz',
    'Rudny',
    'Zhanaozen',
    'Zhezkazgan',
    'Kentau',
    'Balkhash',
    'Satbayev',
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
    'Kapchagay',
  ];

  String? _selectedFrom;
  String? _selectedTo;

  final Color kRedColor = Color(0xFF201731);
  final BoxShadow kDefaultBoxshadow = const BoxShadow(
    color: Color(0xFFDFDFDF),
    spreadRadius: 1,
    blurRadius: 10,
    offset: Offset(2, 2),
  );

  Future<void> _fetchRecommendedPrice() async {
    if (_selectedFrom == null || _selectedTo == null) {
      setState(() {
        _recommendedPrice = null;
        _isFetchingPrice = false;
      });
      return;
    }

    setState(() => _isFetchingPrice = true);
    try {
      final price = await _apiService.fetchRecommendedPrice(_selectedFrom!, _selectedTo!);
      if (mounted) {
        setState(() {
          _recommendedPrice = price;
          _isFetchingPrice = false;
        });
        print('Recommended price fetched: $_recommendedPrice');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recommendedPrice = null;
          _isFetchingPrice = false;
        });
        print('Error fetching recommended price: $e');
      }
    }
  }

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
            'sendTime=${_sendTime.toIso8601String()}, '
            'price=$price, description=${_descriptionController.text}');
        await _apiService.createCourierPost(
          _selectedFrom!,
          _selectedTo!,
          _sendTime,
          price,
          _descriptionController.text,
        ).timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception('Request timed out after 10 seconds');
        });
        print('Courier post created successfully');
      } else {
        print('Creating sender post: from=$_selectedFrom, '
            'to=$_selectedTo, '
            'sendTime=${_sendTime.toIso8601String()}, '
            'price=$price, description=${_descriptionController.text}');
        await _apiService.createSenderPost(
          _selectedFrom!,
          _selectedTo!,
          _sendTime,
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
        print('Navigating to HomeScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(currentUser: widget.currentUser)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
      ),
    );
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
            textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Montserrat',
              fontFamilyFallback: ['Roboto'],
            ),
            colorScheme: ColorScheme.light(
              primary: Color(0xFF201731),
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
      setState(() => _sendTime = pickedDate);
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
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Montserrat',
          fontFamilyFallback: ['Roboto'],
        ),
      ),
      child: Scaffold(
        backgroundColor: Color(0xFFFEF7FF),
        appBar: AppBar(
          title: Text(
            'create_post'.tr(),
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFFFEF7FF),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
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
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                      tabTexts: [
                        'courier_posts'.tr(),
                        'sender_posts'.tr(),
                      ],
                      height: 52,
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
                        color: kRedColor, // #201731
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      activeStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                      inactiveStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'from'.tr(),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade600),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF201731)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        labelStyle: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: _selectedFrom,
                      items: _kazakhstanCities
                          .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city.tr()),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFrom = value;
                          _fetchRecommendedPrice();
                        });
                      },
                      validator: (value) => value == null ? 'Please select a city' : null,
                      menuMaxHeight: 200,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(fontFamily: 'Montserrat', color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'to'.tr(),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade600),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF201731)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        labelStyle: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: _selectedTo,
                      items: _kazakhstanCities
                          .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city.tr()),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTo = value;
                          _fetchRecommendedPrice();
                        });
                      },
                      validator: (value) => value == null ? 'Please select a city' : null,
                      menuMaxHeight: 200,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(fontFamily: 'Montserrat', color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    if (_isFetchingPrice)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_recommendedPrice != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '${_recommendedPrice!.toStringAsFixed(0)} KZT',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'no_price_recommendation'.tr(args: [_selectedFrom ?? '', _selectedTo ?? '']),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade600),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'send_date'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _sendTime.toString().split(' ')[0],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'description'.tr(),
                      controller: _descriptionController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'parcel_price'.tr(),
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'save'.tr(),
                      onPressed: _isLoading ? null : _createPost,
                      color: Color(0xFF201731),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}