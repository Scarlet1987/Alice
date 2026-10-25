// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/services/web/web_server_host.dart';
import 'package:front_porch_ai/ui/dialogs/web_access_setup_dialog.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';

/// Settings → General: the companion-device card. Shows the web server's
/// connection status at a glance and offers one prominent button that opens
/// the guided phone/tablet pairing flow (QR code included). UI only — the
/// pairing itself is owned by [WebAccessSetupDialog] and [WebServerHost].
class CompanionCard extends StatelessWidget {
  const CompanionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WebServerHost>(
      builder: (context, host, _) {
        final running = host.isRunning;
        final statusColor = running
            ? AppColors.bondHighOf(context)
            : AppColors.textTertiary(context);
        return PorchCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(PorchSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.sunkenSurfaceOf(context),
                  borderRadius: BorderRadius.circular(PorchRadius.lg),
                ),
                child: Icon(
                  Icons.phone_iphone,
                  size: 28,
                  color: AppColors.porchAmberOf(context),
                ),
              ),
              const SizedBox(width: PorchSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone & tablet',
                      style: PorchType.title(context),
                    ),
                    const SizedBox(height: PorchSpacing.xs),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: PorchSpacing.xs),
                        Text(
                          running
                              ? 'Companion web app is running'
                              : 'Companion web app is off',
                          style: PorchType.bodySmall(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: PorchSpacing.xs),
                    Text(
                      'Pick up your chats from the couch — pair a phone or '
                      'tablet in under a minute.',
                      style: PorchType.hint(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PorchSpacing.md),
              PorchPrimaryButton(
                label: 'Connect',
                icon: Icons.qr_code_2_outlined,
                onPressed: () => WebAccessSetupDialog.show(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
