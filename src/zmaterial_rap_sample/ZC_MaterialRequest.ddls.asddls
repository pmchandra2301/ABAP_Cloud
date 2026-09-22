@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Material inbound requests'
define root view entity ZC_MaterialRequest
  provider contract transactional_query
  as projection on ZI_MaterialRequest
{
  key RequestUUID,
      Material,
      MaterialType,
      IndustrySector,
      BaseUnit,
      Description,
      Status,
      ExternalMaterial,
      Message,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChanged
}

