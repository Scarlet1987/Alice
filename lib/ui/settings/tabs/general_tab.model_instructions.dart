// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

part of 'general_tab.dart';

/// Model Instructions section, extracted from GeneralTab so the tab itself
/// stays under the 500-line god-file bar. No behaviour change: same
/// dropdown, save/delete buttons, preset chips, and system-prompt field,
/// in the same order.
extension _GeneralTabModelInstructions on GeneralTab {
  Widget _buildModelInstructionsSection(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Model Instructions'),
        const SizedBox(height: 8),
        // Prompt library row simplified for smallest (full chips/load/save use the extracted dialogs)
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: null,
                isExpanded: true,
                hint: const Text(
                  'Load saved prompt...',
                  style: TextStyle(fontSize: 13),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: storageService.presetSettings.savedPrompts
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p['name'],
                        child: Text(
                          p['name']!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (name) {
                  if (name != null) {
                    storageService.presetSettings.loadSavedPrompt(name, (p) {
                      storageService.generationSettings.setSystemPrompt(p);
                    });
                    systemPromptController.text =
                        storageService.generationSettings.systemPrompt;
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Save current prompt',
              icon: Icon(Icons.save, color: AppColors.logWarn),
              onPressed: () => showSavePromptDialog(context, storageService),
            ),
            IconButton(
              tooltip: 'Delete a saved prompt',
              icon: Icon(Icons.delete_outline, color: AppColors.logError),
              onPressed: () =>
                  showDeletePromptDialog(context, storageService),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Built-in preset chips (simplified inline for smallest; full would use PresetChip widget)
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _presetChip(
              '📡 API Default',
              defaultApiSystemPrompt,
              storageService,
            ),
            _presetChip(
              '🖥️ KoboldCPP',
              defaultKoboldSystemPrompt,
              storageService,
            ),
            _presetChip(
              '👥 Group Chat',
              defaultGroupSystemPrompt,
              storageService,
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: systemPromptController,
          maxLines: 5,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'System Prompt...',
            hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
            filled: true,
            fillColor: AppColors.cardOf(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (val) =>
              storageService.generationSettings.setSystemPrompt(val),
        ),
      ],
    );
  }
}
