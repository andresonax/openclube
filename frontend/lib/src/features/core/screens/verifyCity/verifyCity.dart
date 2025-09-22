import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/verifyCityController.dart';

class VerifyCity extends StatefulWidget {
  const VerifyCity({super.key});

  @override
  State<VerifyCity> createState() => _VerifyCityState();
}

class _VerifyCityState extends State<VerifyCity> {
  final verifyCityController = Get.put(VerifyCityController());
  final TextEditingController _typeAheadController = TextEditingController();

  bool searchPerformed = false;

  // Garantimos tipos explícitos
  List<String> options = <String>[];
  List<String> itens = <String>[];
  List<Map<String, dynamic>> completeItens = <Map<String, dynamic>>[];

  @override
  void dispose() {
    _typeAheadController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> searchCities(caracteresCity) async {
    try {
      final response = await verifyCityController.searchCities(caracteresCity);
      if (response is List) {
        return response;
      } else {
        return <dynamic>[];
      }
    } catch (e) {
      return <dynamic>[];
    }
  }

  bool _isIterableAndNotEmpty(dynamic v) => v is Iterable && v.isNotEmpty;

  Future<void> setSelectedCity(String cityName) async {
    String ibge = '';

    try {
      // procura no completeItens (case-insensitive)
      final match = completeItens.firstWhere(
        (m) =>
            (m['cidade']?.toString().toLowerCase() ?? '') ==
            cityName.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (match.isNotEmpty) {
        final possibleKeys = [
          'ibge',
        ];
        for (final k in possibleKeys) {
          if (match.containsKey(k) && match[k] != null) {
            ibge = match[k].toString();
            break;
          }
        }
        if (ibge.isEmpty) {
          // procura qualquer chave que contenha 'ibge'
          for (final entry in match.entries) {
            if (entry.key.toString().toLowerCase().contains('ibge') &&
                entry.value != null) {
              ibge = entry.value.toString();
              break;
            }
          }
        }
      } else {
        final raw = await searchCities(cityName);
        for (final item in raw) {
          if (item == null) continue;
          if (item is Map) {
            final c = item['cidade'] ?? item['municipio'] ?? item['nome'];
            if (c != null &&
                c.toString().toLowerCase() == cityName.toLowerCase()) {
              for (final k in [
                'ibge',
                'codigo_ibge',
                'cod_ibge',
                'codigo',
                'id'
              ]) {
                if (item.containsKey(k) && item[k] != null) {
                  ibge = item[k].toString();
                  break;
                }
              }
              if (ibge.isEmpty) {
                for (final entry in item.entries) {
                  if (entry.key.toString().toLowerCase().contains('ibge') &&
                      entry.value != null) {
                    ibge = entry.value.toString();
                    break;
                  }
                }
              }
              if (ibge.isNotEmpty) break;
            }
          } else {}
        }
      }
    } catch (e) {
      debugPrint('setSelectedCity error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_city_name', cityName);
      await prefs.setString('selected_city_ibge', ibge);
      debugPrint('Saved city="$cityName", ibge="$ibge" to SharedPreferences');
      print('Saved city="$cityName", ibge="$ibge"'); // também print simples
    } catch (e) {
      debugPrint('Error saving to SharedPreferences: $e');
    }

    if (!mounted) return;
    setState(() {
      _typeAheadController.text = cityName;
    });

    Get.toNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOptions = _isIterableAndNotEmpty(options);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(230, 230, 230, 1.0),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.jpeg"),
              fit: BoxFit.fill,
            ),
          ),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo-placeholder.png',
                  height: 220,
                  width: 220,
                ),
                Column(
                  children: [
                    Center(
                      child: Text(
                        'De onde você é?',
                        style: GoogleFonts.indieFlower(
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                                color: Colors.white)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 450,
                      height: 500,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black, width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(4, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 120,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Busque sua cidade',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.indieFlower(
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 23,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade700,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(24),
                                        bottomRight: Radius.circular(24),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 40),
                                        TextField(
                                          controller: _typeAheadController,
                                          decoration: const InputDecoration(
                                            prefixIcon: Icon(Icons.search,
                                                color: Colors.black),
                                            labelText: 'Pesquise a cidade',
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.black),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.black),
                                            ),
                                          ),
                                          style: const TextStyle(
                                              color: Colors.white),
                                          onChanged: (text) async {
                                            if (text.isEmpty) {
                                              if (!mounted) return;
                                              setState(() {
                                                searchPerformed = false;
                                                options = <String>[];
                                                itens = <String>[];
                                                completeItens =
                                                    <Map<String, dynamic>>[];
                                              });
                                              return;
                                            }

                                            if (text.length < 3) {
                                              if (!mounted) return;
                                              setState(() {
                                                searchPerformed = false;
                                                options = <String>[];
                                              });
                                              return;
                                            }

                                            searchPerformed = true;
                                            try {
                                              final raw =
                                                  await searchCities(text);

                                              final List<String> newItens =
                                                  <String>[];
                                              final List<Map<String, dynamic>>
                                                  newComplete =
                                                  <Map<String, dynamic>>[];

                                              for (final item in raw) {
                                                if (item == null) continue;

                                                if (item is Map) {
                                                  final dynamic c =
                                                      item['cidade'];
                                                  final cityStr = (c == null)
                                                      ? ''
                                                      : c.toString().trim();
                                                  if (cityStr.isNotEmpty &&
                                                      !newItens
                                                          .contains(cityStr)) {
                                                    newItens.add(cityStr);
                                                  }
                                                  try {
                                                    newComplete.add(Map<String,
                                                        dynamic>.from(item));
                                                  } catch (_) {}
                                                } else {
                                                  final cityStr =
                                                      item.toString().trim();
                                                  if (cityStr.isNotEmpty &&
                                                      !newItens
                                                          .contains(cityStr)) {
                                                    newItens.add(cityStr);
                                                  }
                                                }
                                              }

                                              if (!mounted) return;
                                              setState(() {
                                                itens = newItens;
                                                options =
                                                    List<String>.from(newItens);
                                                completeItens = newComplete;
                                              });
                                            } catch (e) {
                                              if (!mounted) return;
                                              setState(() {
                                                options = <String>[];
                                                completeItens =
                                                    <Map<String, dynamic>>[];
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Builder(builder: (ctx) {
                                            if (options.isEmpty) {
                                              return Center(
                                                child: Text(
                                                  _typeAheadController
                                                          .text.isEmpty
                                                      ? 'Nenhuma cidade encontrada.'
                                                      : 'Nenhuma cidade encontrada.',
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              );
                                            }

                                            return ListView.separated(
                                              itemCount: options.length,
                                              separatorBuilder: (_, __) =>
                                                  const Divider(
                                                color: Colors.black,
                                                height: 0.5,
                                              ),
                                              itemBuilder: (context, index) {
                                                final title = options[index];
                                                return HoverableListItem(
                                                  title: title,
                                                  onTap: () {
                                                    setSelectedCity(title);
                                                  },
                                                );
                                              },
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -40,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/cidade.png',
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      cacheHeight: 200,
                                      cacheWidth: 200,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HoverableListItem extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const HoverableListItem({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  _HoverableListItemState createState() => _HoverableListItemState();
}

class _HoverableListItemState extends State<HoverableListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedScale(
            scale: _isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isHovered ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                  color: _isHovered ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
