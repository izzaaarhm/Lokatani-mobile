import 'package:flutter/material.dart';

class WeighingDetailScreen extends StatelessWidget {
  const WeighingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with back button
            _buildAppBar(context),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vegetable image and info
                    _buildVegetableHeader(),
                    
                    // Weighing info
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWeighingInfo(),
                          const SizedBox(height: 16),
                          _buildWeighingList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVegetableHeader() {
    return Stack(
      children: [
        // Vegetable image
        Container(
          height: 220,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/image.png'), // Replace with your kale image
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Vegetable name overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.black.withOpacity(0.4),
            child: const Text(
              'Kale',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeighingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date
        Row(
          children: [
            const Text(
              'Senin, dd-mm-yy',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        
        // Weight info
        Row(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah penimbangan: 5',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Berat Total: xx Kg',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeighingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeighingItem(1, "xx", "09:30", true),
        _buildWeighingItem(2, "xx", "09:33", true),
        _buildWeighingItem(3, "xx", "09:37", true),
        _buildWeighingItem(4, "xx", "09:37", true),
        _buildWeighingItem(5, "xx", "09:37", false),
      ],
    );
  }

  Widget _buildWeighingItem(int number, String weight, String time, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Check icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? const Color(0xFF326229) : Colors.transparent,
              border: Border.all(
                color: isCompleted ? const Color(0xFF326229) : Colors.grey,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Weighing info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Penimbangan $number',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Berat: $weight Kg',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Time
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFBCA371), // Golden brown color as shown in the design
            ),
          ),
        ],
      ),
    );
  }
}