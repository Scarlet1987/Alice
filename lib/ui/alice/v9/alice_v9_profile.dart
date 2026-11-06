// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 User profile (combined preview v9): banner, avatar, and
// Your details — Real name, gender identity, Birthday, Pronouns, Bio
// with a 300-word counter. No Persona name: deleted, it is not a
// user-profile field. Gender identity and pronouns are the same rows as
// in Creator; tapping custom opens a text field, and the typed value is
// saved to the profile record with the pick. Nothing here is about a
// main character — characters live in Character creator.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/v9/alice_v9_identity.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

class AliceV9ProfilePage extends StatelessWidget {
  final AliceV9State state;

  const AliceV9ProfilePage({super.key, required this.state});

  Future<void> _pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        DateTime.tryParse(state.userBirthday.text.trim()) ??
        DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Your birthday',
    );
    if (picked != null) {
      state.setUserBirthday(picked);
    }
  }

  Future<void> _save(BuildContext context) async {
    final error = await state.saveUserProfile();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'User profile saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final words = state.bioWordCount;
        final overLimit = words > 300;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              V9Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const V9Heading('Profiles'),
                    const SizedBox(height: 8),
                    const V9Muted(
                      'This is you, not a character. Character setup stays '
                      'in Character creator.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.aliceDark.withValues(alpha: 0.88),
                        border: Border.all(color: AppColors.aliceGreen),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Banner',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const V9Muted(
                            'Your banner image goes here. Banner and avatar '
                            'picking are not wired yet — this box shows the '
                            'place they will live.',
                          ),
                          const SizedBox(height: 16),
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.aliceGreen,
                            child: Text(
                              '○',
                              style: TextStyle(
                                fontSize: 28,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const V9Muted('Your avatar'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    V9Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const V9Heading('Your details'),
                          const SizedBox(height: 8),
                          const V9Muted(
                            'This one is you. This information is how other '
                            'users see you.',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Real name',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: state.userRealName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.pureBlack),
                            decoration: InputDecoration(
                              hintText: 'Your real name',
                              hintStyle: TextStyle(
                                color: AppColors.pureBlack.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.alicePale,
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          V9IdentityRow(
                            label: 'gender identity',
                            options: kV9GenderOptions,
                            customHint: 'Type your gender identity…',
                            value: state.userGender,
                            onPick: (pick) =>
                                state.setUserIdentityPick(
                                  state.userGender,
                                  pick,
                                ),
                            onCustomChanged: (text) =>
                                state.setUserIdentityCustom(
                                  state.userGender,
                                  text,
                                ),
                            saved: state.profileSaved,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Birthday',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: state.userBirthday,
                            readOnly: true,
                            onTap: () => _pickBirthday(context),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.pureBlack),
                            decoration: InputDecoration(
                              hintText: 'Birthday — tap to pick a date',
                              hintStyle: TextStyle(
                                color: AppColors.pureBlack.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.alicePale,
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          V9IdentityRow(
                            label: 'Pronouns',
                            options: kV9PronounOptions,
                            customHint: 'Type your pronouns, e.g. xe/xem…',
                            value: state.userPronouns,
                            onPick: (pick) =>
                                state.setUserIdentityPick(
                                  state.userPronouns,
                                  pick,
                                ),
                            onCustomChanged: (text) =>
                                state.setUserIdentityCustom(
                                  state.userPronouns,
                                  text,
                                ),
                            saved: state.profileSaved,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Bio — about you',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelLarge,
                                ),
                              ),
                              Text(
                                '$words / 300 words',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: overLimit
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.error
                                          : AppColors.alicePale,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: state.userBio,
                            minLines: 4,
                            maxLines: 8,
                            onChanged: (_) => state.bioChanged(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.pureBlack),
                            decoration: InputDecoration(
                              hintText: 'A short bio about you…',
                              hintStyle: TextStyle(
                                color: AppColors.pureBlack.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.pureWhite,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const V9Muted(
                            'Nothing here is about a main character. '
                            'Characters are made and edited in Character '
                            'creator, and listed on Home.',
                          ),
                          const SizedBox(height: 12),
                          V9Button(
                            label: 'Save user profile',
                            onPressed: () => _save(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
