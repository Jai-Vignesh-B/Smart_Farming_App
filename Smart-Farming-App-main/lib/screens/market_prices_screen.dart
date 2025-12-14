
import 'package:farmer_app/models/market_price_model.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:farmer_app/utils/market_constants.dart';

// -----------------------------------------------------------------------------
// Constants & Configuration
// -----------------------------------------------------------------------------

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  int _currentIndex = 0;
  
  // State for data
  List<MarketPrice> _records = [];
  bool _isLoading = false;
  
  // Filter State
  String _selectedState = "Punjab";
  String _selectedCommodity = "Tomato";
  String? _selectedDistrict; // Default to null
  String? _selectedMarket;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 3));
  DateTime _toDate = DateTime.now();

  final ApiService _apiService = ApiService();
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale.languageCode;
    if (_lastLocale != null && _lastLocale != currentLocale) {
      // Locale changed, trigger rebuild by calling setState
      setState(() {
        _lastLocale = currentLocale;
      });
    } else {
      _lastLocale = currentLocale;
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchMarketPrices(
      _selectedState, 
      _selectedDistrict ?? "", 
      _selectedCommodity,
      _selectedMarket ?? ""
    );
    if (mounted) {
      setState(() {
        _records = data;
        _isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC); // Dark vs Light BG

    final List<Widget> screens = [
      HomeScreen(
        records: _records, 
        isLoading: _isLoading, 
        commodity: _selectedCommodity,
        state: _selectedState
      ),
      SearchScreen(
        selectedState: _selectedState,
        selectedCommodity: _selectedCommodity,
        selectedDistrict: _selectedDistrict,
        selectedMarket: _selectedMarket,
        fromDate: _fromDate,
        toDate: _toDate,
        onStateChanged: (val) {
          setState(() {
            _selectedState = val;
            _selectedDistrict = null; // Reset district
            _selectedMarket = null; // Reset market
          });
        },
        onCommodityChanged: (val) => setState(() => _selectedCommodity = val),
        onDistrictChanged: (val) {
          setState(() {
            _selectedDistrict = val;
            _selectedMarket = null; // Reset market
          });
        },
        onMarketChanged: (val) => setState(() => _selectedMarket = val),
        onFromDateChanged: (val) => setState(() => _fromDate = val),
        onToDateChanged: (val) => setState(() => _toDate = val),
        onSearch: () {
          _fetchData();
          setState(() => _currentIndex = 0); // Go to home on search
        },
      ),
      AnalysisScreen(records: _records),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          indicatorColor: isDark ? const Color(0xFF166534) : const Color(0xFFD1FAE5),
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: Icon(LucideIcons.store, color: isDark ? Colors.white54 : null),
              selectedIcon: const Icon(LucideIcons.store, color: Color(0xFF059669)),
              label: 'navMarket'.tr(),
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.search, color: isDark ? Colors.white54 : null),
              selectedIcon: const Icon(LucideIcons.search, color: Color(0xFF059669)),
              label: 'navSearch'.tr(),
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.barChart2, color: isDark ? Colors.white54 : null),
              selectedIcon: const Icon(LucideIcons.barChart2, color: Color(0xFF059669)),
              label: 'navAnalysis'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Screen 1: Home (Market List)
// -----------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  final List<MarketPrice> records;
  final bool isLoading;
  final String commodity;
  final String state;

  const HomeScreen({
    super.key, 
    required this.records, 
    required this.isLoading,
    required this.commodity,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
            : RefreshIndicator(
                onRefresh: () async {}, 
                color: const Color(0xFF059669),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildWelcomeCard(context),
                    const SizedBox(height: 24),
                    StatsRow(records: records),
                    const SizedBox(height: 24),
                    _buildListHeader(context),
                    const SizedBox(height: 12),
                    if (records.isEmpty)
                      _buildEmptyState(context)
                    else
                      ...records.map((r) => MarketCard(record: r)),
                  ],
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.sprout, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('marketTitle'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              Text("liveMandiPrices".tr(), style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("helloFarmer".tr(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF64748B), fontFamily: 'Inter'),
            children: [
              TextSpan(text: "${"latestPricesFor".tr()} "),
              TextSpan(text: commodity, style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
              TextSpan(text: " ${"in".tr()} "),
              TextSpan(text: state, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("marketPrices".tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.grey[500], letterSpacing: 0.5)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey[200], 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Text("${records.length} ${"results".tr()}", style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.grey[700], fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(LucideIcons.tag, size: 48, color: isDark ? Colors.white24 : Colors.grey[300]),
            const SizedBox(height: 16),
            Text("noPricesFound".tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500], fontWeight: FontWeight.w600)),
            Text("tryChangingFilters".tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final List<MarketPrice> records;

  const StatsRow({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    double max = 0;
    double min = double.infinity;
    double sum = 0;
    
    for (var r in records) {
      if (r.modalPrice > max) max = r.modalPrice;
      if (r.modalPrice < min) min = r.modalPrice;
      sum += r.modalPrice;
    }
    
    double avg = records.isEmpty ? 0 : sum / records.length;
    if (min == double.infinity) min = 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildStatCard(
            context,
            "average".tr(), 
            "₹${avg.toStringAsFixed(0)}", 
            LucideIcons.indianRupee, 
            Colors.blue
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            "highest".tr(), 
            "₹${max.toStringAsFixed(0)}", 
            LucideIcons.trendingUp, 
            const Color(0xFF059669) // Emerald
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            "lowest".tr(), 
            "₹${min.toStringAsFixed(0)}", 
            LucideIcons.trendingDown, 
            Colors.pink
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    bool isPrimary = label == "average".tr();
    return Container(
      width: 140,
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? color : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isPrimary ? color.withValues(alpha: 0.3) : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isPrimary ? null : Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isPrimary ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: isPrimary ? Colors.white : color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: isPrimary ? Colors.blue.shade100 : (isDark ? Colors.white60 : Colors.grey.shade500), fontWeight: FontWeight.w600)),
              Text(value, style: TextStyle(fontSize: 20, color: isPrimary ? Colors.white : (isDark ? Colors.white : Colors.grey.shade800), fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

class MarketCard extends StatelessWidget {
  final MarketPrice record;

  const MarketCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    // Card Colors
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade100;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryTextColor = isDark ? Colors.white60 : Colors.grey[500];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.commodity.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                      child: Text(record.variety, style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5), // Emerald 900 vs 50
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFD1FAE5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("modalPrice".tr(), style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                    Text("₹${record.modalPrice.toInt()}", style: const TextStyle(fontSize: 18, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 14, color: isDark ? Colors.white38 : Colors.grey[400]),
              const SizedBox(width: 4),
              Expanded(
                child: Text("${record.market}, ${record.district}", 
                  style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(LucideIcons.calendar, size: 14, color: isDark ? Colors.white38 : Colors.grey[400]),
              const SizedBox(width: 4),
              Text(record.arrivalDate, style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w500)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceTag("min".tr(), record.minPrice, isDark ? Colors.white60 : Colors.grey[500]!, isDark),
                _buildPriceTag("max".tr(), record.maxPrice, isDark ? Colors.white70 : Colors.grey[700]!, isDark),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPriceTag(String label, double price, Color color, bool isDark) {
    return Row(
      children: [
        Text("$label: ", style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])),
        Text("₹${price.toInt()}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Screen 2: Search (Filters)
// -----------------------------------------------------------------------------

class SearchScreen extends StatelessWidget {
  final String selectedState;
  final String selectedCommodity;
  final String? selectedDistrict;
  final String? selectedMarket;
  final DateTime fromDate;
  final DateTime toDate;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<String> onCommodityChanged;
  final ValueChanged<String?> onDistrictChanged;
  final ValueChanged<String?> onMarketChanged;
  final ValueChanged<DateTime> onFromDateChanged;
  final ValueChanged<DateTime> onToDateChanged;
  final VoidCallback onSearch;

  const SearchScreen({
    super.key,
    required this.selectedState,
    required this.selectedCommodity,
    required this.selectedDistrict,
    required this.selectedMarket,
    required this.fromDate,
    required this.toDate,
    required this.onStateChanged,
    required this.onCommodityChanged,
    required this.onDistrictChanged,
    required this.onMarketChanged,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    // Get dependent lists
    List<String> rawDistricts = MarketConstants.stateDistrictMap[selectedState] ?? [];
    List<String> districts = ["All Districts", ...rawDistricts];
    List<String> markets = ["All Markets"]; // In a real app, this would come from API based on district

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text("searchFilters".tr(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("filters".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 24),
                  
                  // Commodity
                  _buildDropdown(
                    context: context,
                    label: "selectCommodity".tr(),
                    value: selectedCommodity,
                    items: MarketConstants.popularCommodities,
                    onChanged: (val) {
                      if (val != null) onCommodityChanged(val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // State
                  _buildDropdown(
                    context: context,
                    label: "selectState".tr(),
                    value: selectedState,
                    items: MarketConstants.indianStates,
                    onChanged: (val) {
                      if (val != null) onStateChanged(val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // District
                  _buildDropdown(
                    context: context,
                    label: "selectDistrict".tr(),
                    value: selectedDistrict,
                    items: districts,
                    hint: "selectStateFirst".tr(),
                    onChanged: onDistrictChanged,
                  ),
                  const SizedBox(height: 20),

                  // Market
                  _buildDropdown(
                    context: context,
                    label: "selectMarket".tr(),
                    value: selectedMarket,
                    items: markets,
                    hint: "selectDistrictFirst".tr(),
                    onChanged: onMarketChanged,
                  ),
                  const SizedBox(height: 20),

                  // Date Range
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(context, "from".tr(), fromDate, onFromDateChanged),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(context, "to".tr(), toDate, onToDateChanged),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D), // Green 700
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: Text("loadPrices".tr()),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for scrolling
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label, 
    required String? value, 
    required List<String> items, 
    required ValueChanged<String?> onChanged,
    String? hint
  }) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    // Validate value matches items
    String? effectiveValue = value;
    if (value != null && !items.contains(value)) {
      effectiveValue = null;
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          hint: hint != null ? Text(hint, style: TextStyle(color: isDark ? Colors.white54 : null)) : null,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(LucideIcons.chevronDown, size: 20, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item.tr(), style: TextStyle(fontSize: 16, color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w600)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime date, ValueChanged<DateTime> onChanged) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
             borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 18, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              DateFormat('d/M/yyyy').format(date),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Screen 3: Analysis (Chart + Gemini)
// -----------------------------------------------------------------------------

class AnalysisScreen extends StatefulWidget {
  final List<MarketPrice> records;

  const AnalysisScreen({super.key, required this.records});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Process data for chart: Group by Date and Calculate Averages
    final Map<String, List<MarketPrice>> groupedByDate = {};
    
    for (var record in widget.records) {
      if (!groupedByDate.containsKey(record.arrivalDate)) {
        groupedByDate[record.arrivalDate] = [];
      }
      groupedByDate[record.arrivalDate]!.add(record);
    }
    
    // Create sorted list of aggregated data
    final List<MarketPrice> sortedRecords = [];
    
    final sortedDates = groupedByDate.keys.toList();
    sortedDates.sort((a, b) {
      DateTime? parseDate(String dateStr) {
        try {
          // Normalize separators
          String normalized = dateStr.replaceAll('-', '/').replaceAll('.', '/');
          List<String> parts = normalized.split('/');
          if (parts.length == 3) {
            // Assume d/M/y or d/M/yyyy
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            if (year < 100) year += 2000; // Handle 2-digit year
            return DateTime(year, month, day);
          }
        } catch (e) {
          return null;
        }
        return null;
      }

      final dateA = parseDate(a) ?? DateTime.now();
      final dateB = parseDate(b) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
    
    for (var date in sortedDates) {
      final records = groupedByDate[date]!;
      double sumModal = 0;
      double minPrice = double.infinity;
      double maxPrice = 0;
      
      for (var r in records) {
        sumModal += r.modalPrice;
        if (r.minPrice < minPrice) minPrice = r.minPrice;
        if (r.maxPrice > maxPrice) maxPrice = r.maxPrice;
      }
      
      if (minPrice == double.infinity) minPrice = 0;
      
      // Create synthetic record for the day
      sortedRecords.add(MarketPrice(
        state: records.first.state,
        district: records.first.district,
        market: "All Markets",
        commodity: records.first.commodity,
        variety: "Average",
        arrivalDate: date,
        minPrice: minPrice,
        maxPrice: maxPrice,
        modalPrice: sumModal / records.length,
      ));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text("marketIntelligence".tr(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            ],
          ),
        ),
        Text("visualPriceTrends".tr(), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
        const SizedBox(height: 24),

        if (widget.records.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(LucideIcons.barChart2, size: 48, color: isDark ? Colors.white30 : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("noDataToAnalyze".tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[500], fontWeight: FontWeight.w600)),
                  Text("pleaseSearchFirst".tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          )
        else ...[
          // Chart Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("priceTrends".tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text("pinchToZoom".tr(), style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true, 
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.grey.shade100, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < sortedRecords.length) {
                                  final date = sortedRecords[value.toInt()].arrivalDate;
                                  final parts = date.split('/');
                                  if (parts.length >= 2) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text("${parts[0]}/${parts[1]}", style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[400])),
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                              interval: (sortedRecords.length / 5).ceilToDouble(), 
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text("₹${value.toInt()}", style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[400]));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Min Price (Red/Pink)
                          LineChartBarData(
                            spots: sortedRecords.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.minPrice)).toList(),
                            isCurved: false, // Jagged lines as per image
                            color: Colors.pinkAccent,
                            barWidth: 2,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4, 
                                  color: Colors.white, 
                                  strokeWidth: 2, 
                                  strokeColor: Colors.pinkAccent
                                );
                              }
                            ),
                            belowBarData: BarAreaData(show: false),
                          ),
                          // Max Price (Blue)
                          LineChartBarData(
                            spots: sortedRecords.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.maxPrice)).toList(),
                            isCurved: false, // Jagged lines
                            color: Colors.blueAccent,
                            barWidth: 2,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4, 
                                  color: Colors.white, 
                                  strokeWidth: 2, 
                                  strokeColor: Colors.blueAccent
                                );
                              }
                            ),
                            belowBarData: BarAreaData(show: false),
                          ),
                          // Modal Price (Green)
                          LineChartBarData(
                            spots: sortedRecords.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.modalPrice)).toList(),
                            isCurved: false, // Jagged lines
                            color: const Color(0xFF059669),
                            barWidth: 2,
                            dotData: FlDotData(
                              show: true, 
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4, 
                                  color: Colors.white, 
                                  strokeWidth: 2, 
                                  strokeColor: const Color(0xFF059669)
                                );
                              }
                            ),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  "₹${spot.y.toInt()}",
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem("min".tr(), Colors.redAccent, isDark),
                    const SizedBox(width: 16),
                    _buildLegendItem("max".tr(), Colors.blueAccent, isDark),
                    const SizedBox(width: 16),
                    _buildLegendItem("modalPrice".tr(), const Color(0xFF059669), isDark),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Daily Cards List
          ...sortedRecords.map((record) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFD1FAE5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM d, yyyy').format(DateFormat('dd/MM/yyyy').parse(record.arrivalDate)), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
                      ),
                      child: Text("₹${record.modalPrice.toInt()}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPriceStat("min".tr(), record.minPrice, LucideIcons.trendingDown, Colors.redAccent, isDark),
                    _buildPriceStat("max".tr(), record.maxPrice, LucideIcons.trendingUp, Colors.blueAccent, isDark),
                    _buildPriceStat("modalPrice".tr(), record.modalPrice, LucideIcons.barChart2, const Color(0xFF059669), isDark),
                  ],
                ),
              ],
            ),
          )),
        ]
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPriceStat(String label, double price, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text("₹${price.toInt()}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[500], fontWeight: FontWeight.w500)),
      ],
    );
  }
}
