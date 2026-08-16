import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../bloc/couple_bloc.dart';
import '../bloc/couple_event.dart';
import '../bloc/couple_state.dart';
import 'relationship_setup_screen.dart';

class JoinRelationshipScreen extends StatefulWidget {
  const JoinRelationshipScreen({super.key});

  @override
  State<JoinRelationshipScreen> createState() => _JoinRelationshipScreenState();
}

class _JoinRelationshipScreenState extends State<JoinRelationshipScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _joinCouple() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<CoupleBloc>().add(
            JoinRelationshipRequested(_codeController.text.trim().toUpperCase()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoupleBloc, CoupleState>(
      listener: (context, state) {
        if (state is CouplePaired) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RelationshipSetupScreen(relationship: state.relationship),
            ),
          );
        } else if (state is CoupleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is CoupleLoading;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Partner Code',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask your partner for their 6-digit invitation code.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 36),

                    CustomTextField(
                      controller: _codeController,
                      hintText: 'e.g. 7K2M9X',
                      labelText: '6-Digit Code',
                      prefixIcon: Icons.key_outlined,
                      keyboardType: TextInputType.text,
                      onChanged: (val) {
                        _codeController.value = TextEditingValue(
                          text: val.toUpperCase(),
                          selection: _codeController.selection,
                        );
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter code';
                        }
                        if (value.trim().length < 6) {
                          return 'Code must be 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Join Partner',
                      onPressed: _joinCouple,
                      isLoading: isLoading,
                      variant: ButtonVariant.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
