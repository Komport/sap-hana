variable "is_single_node_hana" {
  description = "Checks if single node hana architecture scenario is being deployed"
  default     = false
}

# Set defaults
locals {
  # Filter the list of databases to only HANA platform entries
  hana-databases = [
    for database in var.databases : database
    if try(database.platform, "NONE") == "HANA"
  ]
  hdb    = try(local.hana-databases[0], {})
  hdb_ha = try(local.hdb.high_availability, "false")
  hdb_os = try(local.hdb.os,
    {
      "publisher" = "suse",
      "offer"     = "sles-sap-12-sp5",
      "sku"       = "gen1"
  })

  # iSCSI target device(s) is only created when below conditions met:
  # - iscsi is defined in input JSON
  # - AND
  #   - HANA database has high_availability set to true
  #   - HANA database uses SUSE
  iscsi_count = lookup(var.infrastructure, "iscsi", {}) != {} && (length(local.hana-databases) > 0 ? (local.hdb_ha && upper(local.hdb_os.publisher) == "SUSE") : false) ? var.infrastructure.iscsi.iscsi_count : 0

  # Shortcut to iSCSI definition
  iscsi = merge(lookup(var.infrastructure, "iscsi", {}), { "iscsi_count" = "${local.iscsi_count}" })

  # Shortcut to subnet block for iSCSI in input JSON
  subnet_iscsi = merge({ "is_existing" = "false" }, lookup(var.infrastructure.vnets.sap, "subnet_iscsi", {}))
}
