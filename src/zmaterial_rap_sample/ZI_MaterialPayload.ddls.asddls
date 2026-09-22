@EndUserText.label: 'Material inbound payload'
define abstract entity ZI_MaterialPayload {
  material        : abap.char(40);
  materialType    : abap.char(4);
  industrySector  : abap.char(1);
  baseUnit        : abap.unit(3);
  description     : abap.char(40);
  action          : abap.char(6);
}

