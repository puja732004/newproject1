import 'package:flutter/material.dart';

const primaryDark = Color(0xFF1E1E1E);
const primaryPurple = Color(0xFF8B5CF6);

// ================= Add Card Page =================
class AddCardPageSimple extends StatefulWidget {
  const AddCardPageSimple({super.key});

  @override
  State<AddCardPageSimple> createState() => _AddCardPageSimpleState();
}

class _AddCardPageSimpleState extends State<AddCardPageSimple> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController numberController = TextEditingController();
  final TextEditingController ccvController = TextEditingController();
  final TextEditingController expController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  Widget _buildCardField(String hintText, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: (hintText == 'Card Number' || hintText == 'CCV')
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  void _saveCard() {
    if (_formKey.currentState!.validate()) {
      final cardDetails = {
        'number': numberController.text,
        'ccv': ccvController.text,
        'exp': expController.text,
        'name': nameController.text,
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(card: cardDetails),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Card',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryDark),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCardField('Card Number', numberController),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildCardField('CCV', ccvController)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildCardField('Exp', expController)),
                ],
              ),
              const SizedBox(height: 15),
              _buildCardField('Cardholder Name', nameController),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _saveCard,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Payment Screen =================
class PaymentScreen extends StatelessWidget {
  final Map<String, dynamic> card; // Only the newly added card

  const PaymentScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final displayNumber = card['number'].length >= 4
        ? '**** ${card['number'].substring(card['number'].length - 4)}'
        : card['number'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AddCardPageSimple()),
            );
          },
        ),
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cards', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _PaymentMethodItem(
              text: displayNumber,
              trailingIcon: const Icon(Icons.credit_card, color: Colors.red, size: 20),
            ),
            const SizedBox(height: 30),
            const Text('Paypal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const _PaymentMethodItem(
              text: 'Cloth@gmail.com',
              trailingIcon: SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Payment Method Item =================
class _PaymentMethodItem extends StatelessWidget {
  final String text;
  final Widget trailingIcon;

  const _PaymentMethodItem(
      {super.key, required this.text, required this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500)),
          Row(
            children: [
              trailingIcon,
              const SizedBox(width: 15),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
