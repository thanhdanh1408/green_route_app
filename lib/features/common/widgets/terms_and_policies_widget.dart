import 'package:flutter/material.dart';
import '../../../core/constants/terms_policies.dart';
import '../screens/terms_and_policies_screen.dart';

class TermsAndPoliciesWidget extends StatelessWidget {
  const TermsAndPoliciesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: TermsAndPolicies.allTerms.length,
      itemBuilder: (context, index) {
        final key = TermsAndPolicies.allTerms.keys.toList()[index];
        final title = TermsAndPolicies.termsTitle[key] ?? '';
        final description = TermsAndPolicies.termsDescription[key] ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              description,
              style: const TextStyle(fontSize: 13),
            ),
            trailing: const Icon(Icons.arrow_forward, color: Colors.green),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TermsAndPoliciesScreen(
                    initialTermType: key,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
