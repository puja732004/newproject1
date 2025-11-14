import 'package:flutter/material.dart';
import 'package:newproject1/screens/userhome/categorydetailpage.dart';
import 'package:newproject1/screens/userhome/homepage.dart';

// --- Data Model for Categories (Simulating Firestore Data) ---
class Category {
  final String title;
  final String imagePath;
  Category({required this.title, required this.imagePath});
}

// --- Stateful Category Page (Handles Search and UI State) ---
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});


  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  // 1. Initial Data Source
  final List<Category> _allCategories = [
    Category(title: 'Ethnic Wears', imagePath: 'assets/ethnic.jpg'),
    Category(title: 'Mens Wears', imagePath: 'assets/mens wear1.jpg'),
    Category(title: 'Shoes', imagePath: 'assets/shoes.png'),
    Category(title: 'Beauty', imagePath: 'assets/beauty.png'),
    Category(title: 'Groceries', imagePath: 'assets/grocessories.jpg'),
  ];

  // 2. State Variables
  List<Category> _filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();
  String _lastSuccessfulSearch = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredCategories = _allCategories;
    // Listen for changes in the search field to trigger filtering
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCategories);
    _searchController.dispose();
    super.dispose();
  }


  // 3. Filtering Logic: Updates the UI based on the search query
  Future<void> _filterCategories() async {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _allCategories;
        _isLoading = false;
      } else {
        // Filter the list to include only items whose title contains the query
        _filteredCategories = _allCategories.where((category) {
          return category.title.toLowerCase().contains(query);
        }).toList();
      }
    });
    // ⭐️ Start Loading and clear old results/state
    setState(() {
      _isLoading = true;
      _filteredCategories = []; // Clear current list while loading
    });

    // ⭐️ SIMULATE ASYNC FIRESTORE CALL (Awaiting 1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));
    // 3a. Perform the filtering logic after the simulated delay
    final results = _allCategories.where((category) {
      return category.title.toLowerCase().contains(query);
    }).toList();

    // 3b. Update state with results and stop loading
    setState(() {
      _filteredCategories = results;
      _isLoading = false; // Stop loading regardless of success/failure
    });
    // 3b. Check for navigation condition (successful product search)
    // We only navigate if the query is not empty, results were found, and we haven't already navigated for this query.
    if (query.isNotEmpty &&
        _filteredCategories.isNotEmpty &&
        query != _lastSuccessfulSearch.toLowerCase()) {

      // Assume finding any result here means a successful "product" search
      _lastSuccessfulSearch = query;

      // Perform the navigation to the Search Results Page (e.g., Jacket page)
      Navigator.push(
        context,
        MaterialPageRoute(
          // Navigate to a page that shows the results (like your Search Result-1.jpg image)
          builder: (context) => CategoryDetailPage(categoryName: query),
        ),
      ).then((_) {
        // Optional: Reset last successful search when user comes back
        _lastSuccessfulSearch = '';
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    // Determine if we should show the "No Results" UI
    final bool showNoResults = _searchController.text.isNotEmpty && _filteredCategories.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shop by Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      // --- Dynamic Body Content based on search results ---
      body: showNoResults
          ? _buildNoResultsUI(context)
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: _buildSearchBar(),
          ),
          // Only show the list if there are results or the search is empty
          if (_filteredCategories.isNotEmpty || _searchController.text.isEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = _filteredCategories[index];
                  return _buildCategoryItem(
                    context,
                    category.title,
                    category.imagePath,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- Search Bar Widget with Controller and Clear Functionality ---
  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextField(
        controller: _searchController, // Linked to the state controller
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(color: Color(0xFF888888)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF888888)),
            onPressed: () {
              _searchController.clear();
              _filterCategories(); // Manually trigger filter reset
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 12),
        ),
      ),
    );
  }

  // --- No Results Found UI ---
  Widget _buildNoResultsUI(BuildContext context) {
    return Column(
      children: [
        // Search Bar remains visible at the top (with the failed search term)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: _buildSearchBar(),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5B03E), width: 8),
                      ),
                    ),
                    const Icon(Icons.search, size: 60, color: Color(0xFFE5B03E)),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Sorry, we couldn\'t find any\nmatching result for your Search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the HomePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePageUI(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9370DB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    'Explore Categories',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Category Item Widget ---
  Widget _buildCategoryItem(
      BuildContext context,
      String title,
      String imagePath,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryDetailPage(categoryName: title),
            ),
          );
        },
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(imagePath),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// Based on CategoryDetailPage, modified to show the full product result layout
class ProductSearchResultsPage extends StatelessWidget {
  final String searchTerm;
  final int resultCount;

  const ProductSearchResultsPage({
    super.key,
    required this.searchTerm,
    this.resultCount = 53, // Example result count
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // The search bar is often kept at the top of the results screen
        automaticallyImplyLeading: false, // Don't show default back button
        title: _buildResultsSearchBar(context, searchTerm),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips Section
          _buildFilterChips(context),

          // Result Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '$resultCount Results Found',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          // Product Grid (Simulated)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.65, // Adjust for product card height
              ),
              itemCount: 4, // Show 4 items as in the image
              itemBuilder: (context, index) {
                // Use a simplified product card
                return const ProductCardPlaceholder();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build the search bar on the results page
  Widget _buildResultsSearchBar(BuildContext context, String term) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Text(term, style: const TextStyle(color: Colors.black, fontSize: 16)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.black),
            onPressed: () => Navigator.pop(context), // Go back to clear search
          ),
        ],
      ),
    );
  }

  // Widget to build the filter and sort chips
  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Filter Icon Chip (Purple)
          _buildFilterChip(
            icon: Icons.tune,
            label: '2',
            color: const Color(0xFF9370DB),
            textColor: Colors.white,
          ),
          const SizedBox(width: 8),

          // Regular Chips
          _buildFilterChip(label: 'On Sale', isDropdown: false),
          const SizedBox(width: 8),

          _buildFilterChip(
            label: 'Price',
            isDropdown: true,
            onTap: () {
              // Show the sort modal when 'Sort by' is tapped.
              showModalBottomSheet(
                context: context,
                builder: (context) => const SortByModal(),
              );
            },
          ),
          const SizedBox(width: 8),

          _buildFilterChip(
            label: 'Sort by',
            isDropdown: true,
            onTap: () {
              // Show the sort modal when 'Sort by' is tapped.
              showModalBottomSheet(
                context: context,
                builder: (context) => const SortByModal(),
              );
            },
          ),
          const SizedBox(width: 8),

          _buildFilterChip(label: 'Men', isDropdown: true, color: const Color(0xFF9370DB), textColor: Colors.white),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    String? count,
    bool isDropdown = false,
    Color color = const Color(0xFFF0F0F0),
    Color textColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(icon, size: 16, color: textColor),
              ),
            Text(
              label,
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            if (isDropdown)
              Icon(Icons.keyboard_arrow_down, size: 16, color: textColor),
          ],
        ),
      ),
    );
  }
}

// Placeholder for the product cards in the grid
class ProductCardPlaceholder extends StatelessWidget {
  const ProductCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Expanded(
            child: Center(
              child: Image.asset('assets/placeholder_jacket.jpg'), // Placeholder image
            ),
          ),
          // Product details
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$XX.XX', style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SortByModal extends StatelessWidget {
  const SortByModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Clear', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const Text(
                'Sort by',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),

          // Sorting Options
          _buildSortOption(
            context,
            label: 'Recommended',
            isSelected: true, // Example selected state
          ),
          _buildSortOption(context, label: 'Newest'),
          _buildSortOption(context, label: 'Lowest - Highest Price'),
          _buildSortOption(context, label: 'Highest - Lowest Price'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSortOption(
      BuildContext context, {
        required String label,
        bool isSelected = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9370DB).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          border: isSelected
              ? Border.all(color: const Color(0xFF9370DB), width: 0) // No visible border, controlled by background color
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF9370DB) : Colors.black,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFF9370DB),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}