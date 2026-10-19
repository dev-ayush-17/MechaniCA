import 'service_definition.dart';

/// Seed catalog from docs/prd/05-functional-requirements.md (FR-BOOK-003).
const seedServices = <ServiceDefinition>[
  ServiceDefinition(
    code: 'general_service',
    name: 'General Service',
    description: 'Periodic inspection, fluids, and adjustments',
    baseLaborPaise: 59900,
    durationMin: 60,
    active: true,
    sortOrder: 1,
  ),
  ServiceDefinition(
    code: 'oil_change',
    name: 'Oil Change',
    description: 'Engine oil and filter replacement',
    baseLaborPaise: 39900,
    durationMin: 45,
    active: true,
    sortOrder: 2,
  ),
  ServiceDefinition(
    code: 'engine_issue',
    name: 'Engine Issue',
    description: 'Diagnosis and repair of running problems',
    baseLaborPaise: 49900,
    durationMin: 90,
    active: true,
    sortOrder: 3,
  ),
  ServiceDefinition(
    code: 'brake_repair',
    name: 'Brake Repair',
    description: 'Brake pad, disc, and fluid work',
    baseLaborPaise: 34900,
    durationMin: 45,
    active: true,
    sortOrder: 4,
  ),
  ServiceDefinition(
    code: 'breakdown',
    name: 'Breakdown assist',
    description: 'Roadside help when the vehicle will not run',
    baseLaborPaise: 49900,
    durationMin: 60,
    active: true,
    sortOrder: 5,
  ),
];
