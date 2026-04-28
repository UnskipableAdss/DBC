// lib/data/edi_constants.dart
// ─────────────────────────────────────────────────────────────────────────────
// EDI Segment & Element Dictionary
// Replicates the JS lookup tables from the reference repo and extends them
// with the full X12 + EDIFACT vocabulary.
// ─────────────────────────────────────────────────────────────────────────────

/// Human-readable names for every standard X12 / EDIFACT segment ID.
const Map<String, String> kSegmentNames = {
  // ── Interchange / Envelope ─────────────────────────────────────────────────
  'ISA': 'Interchange Control Header',
  'IEA': 'Interchange Control Trailer',
  'GS': 'Functional Group Header',
  'GE': 'Functional Group Trailer',
  'ST': 'Transaction Set Header',
  'SE': 'Transaction Set Trailer',

  // ── EDIFACT Envelope ───────────────────────────────────────────────────────
  'UNA': 'Service String Advice',
  'UNB': 'Interchange Header',
  'UNZ': 'Interchange Trailer',
  'UNG': 'Functional Group Header (EDIFACT)',
  'UNE': 'Functional Group Trailer (EDIFACT)',
  'UNH': 'Message Header',
  'UNT': 'Message Trailer',

  // ── 204 / 210 / 211 Motor Carrier ──────────────────────────────────────────
  'BGN': 'Beginning Segment',
  'BL': 'Bill of Lading',
  'B2': 'Beginning Segment for Shipment Information',
  'B2A': 'Set Purpose',
  'B3': 'Bill of Lading Line Item Number',
  'B3A': 'Bill of Lading Identification',

  // ── 850 Purchase Order ─────────────────────────────────────────────────────
  'BEG': 'Beginning Segment for Purchase Order',
  'CUR': 'Currency',
  'FOB': 'F.O.B. Related Instructions',
  'ITD': 'Terms of Sale/Deferred Terms of Sale',
  'DTM': 'Date/Time Reference',
  'N1': 'Name',
  'N2': 'Additional Name Information',
  'N3': 'Address Information',
  'N4': 'Geographic Location',
  'PO1': 'Baseline Item Data',
  'PO4': 'Item Physical Details',
  'PID': 'Product/Item Description',
  'PO3': 'Additional Item Detail',
  'CTT': 'Transaction Totals',
  'AMT': 'Monetary Amount',

  // ── 856 Advance Ship Notice ────────────────────────────────────────────────
  'BSN': 'Beginning Segment for Ship Notice',
  'HL': 'Hierarchical Level',
  'TD1': 'Carrier Details (Quantity and Weight)',
  'TD3': 'Carrier Details (Equipment)',
  'TD4': 'Carrier Details (Special Handling or Hazardous Materials)',
  'TD5': 'Carrier Details (Routing Sequence/Transit Time)',
  'MAN': 'Marks and Numbers',
  'PKG': 'Marking, Packaging, Loading',

  // ── 810 Invoice ────────────────────────────────────────────────────────────
  'BIG': 'Beginning Segment for Invoice',
  'NTE': 'Note/Special Instruction',
  'IT1': 'Baseline Item Data (Invoice)',
  'TXI': 'Tax Information',
  'SAC': 'Service, Promotion, Allowance, or Charge Information',
  'TDS': 'Total Monetary Value Summary',
  'CAD': 'Carrier Detail',

  // ── Common across transactions ─────────────────────────────────────────────
  'REF': 'Reference Identification',
  'PER': 'Administrative Communications Contact',
  'MSG': 'Message Text',
  'LIN': 'Item Identification',
  'SN1': 'Item Detail (Shipment)',
  'ACK': 'Line Item Acknowledgment',
  'SHP': 'Shipped/Received Information',
  'QTY': 'Quantity',
  'SCH': 'Line Item Schedule',
  'MEA': 'Measurements',
  'CTP': 'Pricing Information',
  'TC2': 'Commodity',
  'V1': 'Vehicle Identification',
  'V4': 'Car Handling Information',
  'W2': 'Equipment Identification',
  'W4': 'Receipt or Dispatch Information',
  'W6': 'Storage/Shipping Order Identification',
  'W09': 'Storage/Shipping Order Item Detail',
  'W12': 'Warehouse Item Detail',
  'W14': 'Total Receipt Information',
  'W15': 'Warehouse Summary Information',
  'W17': 'Warehouse Receipt Identification',
  'W19': 'Warehouse Adjustment Identification',
  'W20': 'Warehouse Activity Summary',
  'W21': 'Warehouse Item Activity',
  'W22': 'Warehouse Item Detail (Reversal)',
  'W27': 'Carrier Detail',
};

/// Element-level descriptions keyed by "SEGMENT-INDEX" (1-based, zero-padded to 2 digits).
/// Example: 'ISA-01' → 'Authorization Information Qualifier'
const Map<String, String> kElementDescriptions = {
  // ISA elements
  'ISA-01': 'Authorization Information Qualifier',
  'ISA-02': 'Authorization Information',
  'ISA-03': 'Security Information Qualifier',
  'ISA-04': 'Security Information',
  'ISA-05': 'Interchange ID Qualifier (Sender)',
  'ISA-06': 'Interchange Sender ID',
  'ISA-07': 'Interchange ID Qualifier (Receiver)',
  'ISA-08': 'Interchange Receiver ID',
  'ISA-09': 'Interchange Date',
  'ISA-10': 'Interchange Time',
  'ISA-11': 'Repetition Separator / Standards ID',
  'ISA-12': 'Interchange Control Version Number',
  'ISA-13': 'Interchange Control Number',
  'ISA-14': 'Acknowledgment Requested',
  'ISA-15': 'Usage Indicator',
  'ISA-16': 'Component Element Separator',

  // GS elements
  'GS-01': 'Functional Identifier Code',
  'GS-02': 'Application Sender\'s Code',
  'GS-03': 'Application Receiver\'s Code',
  'GS-04': 'Date',
  'GS-05': 'Time',
  'GS-06': 'Group Control Number',
  'GS-07': 'Responsible Agency Code',
  'GS-08': 'Version / Release / Industry Identifier Code',

  // ST elements
  'ST-01': 'Transaction Set Identifier Code',
  'ST-02': 'Transaction Set Control Number',
  'ST-03': 'Implementation Convention Reference',

  // BEG elements
  'BEG-01': 'Transaction Set Purpose Code',
  'BEG-02': 'Purchase Order Type Code',
  'BEG-03': 'Purchase Order Number',
  'BEG-04': 'Release Number',
  'BEG-05': 'Date',
  'BEG-06': 'Contract Number',

  // DTM elements
  'DTM-01': 'Date/Time Qualifier',
  'DTM-02': 'Date',
  'DTM-03': 'Time',
  'DTM-04': 'Time Code',
  'DTM-05': 'Date Time Period Format Qualifier',
  'DTM-06': 'Date Time Period',

  // N1 elements
  'N1-01': 'Entity Identifier Code',
  'N1-02': 'Name',
  'N1-03': 'Identification Code Qualifier',
  'N1-04': 'Identification Code',

  // REF elements
  'REF-01': 'Reference Identification Qualifier',
  'REF-02': 'Reference Identification',
  'REF-03': 'Description',

  // PO1 elements
  'PO1-01': 'Assigned Identification',
  'PO1-02': 'Quantity Ordered',
  'PO1-03': 'Unit or Basis for Measurement Code',
  'PO1-04': 'Unit Price',
  'PO1-05': 'Basis of Unit Price Code',
  'PO1-06': 'Product/Service ID Qualifier',
  'PO1-07': 'Product/Service ID',

  // HL elements
  'HL-01': 'Hierarchical ID Number',
  'HL-02': 'Hierarchical Parent ID Number',
  'HL-03': 'Hierarchical Level Code',
  'HL-04': 'Hierarchical Child Code',
};

/// Functional Identifier Codes (GS01) → Transaction set name.
const Map<String, String> kFunctionalGroups = {
  'FA': '997/999 – Functional Acknowledgment',
  'PO': '850 – Purchase Order',
  'PR': '855 – Purchase Order Acknowledgment',
  'SH': '856 – Ship Notice / Manifest',
  'IN': '810 – Invoice',
  'SM': '204 – Motor Carrier Shipment',
  'FR': '210 – Motor Carrier Freight Details',
  'QM': '214 – Transportation Carrier Shipment Status Message',
  'IM': '211 – Motor Carrier Bill of Lading',
  'WR': '944 – Warehouse Stock Transfer Shipment Advice',
  'OW': '940 – Warehouse Shipping Order',
  'WS': '945 – Warehouse Shipping Advice',
  'WA': '947 – Warehouse Inventory Adjustment Advice',
};

/// Usage Indicator (ISA15)
const Map<String, String> kUsageIndicators = {
  'T': 'Test',
  'P': 'Production',
  'I': 'Information',
};
