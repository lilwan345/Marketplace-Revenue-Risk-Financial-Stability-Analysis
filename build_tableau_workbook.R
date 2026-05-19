#
# Build a Tableau packaged workbook (.twbx) from the Tableau-ready CSV files.
# The workbook is intentionally generated from code so the Tableau artifact can
# be rebuilt after any metric or dataset refresh.
#

options(stringsAsFactors = FALSE)

data_dir <- "tableau_data"
out_dir <- "tableau_workbook"
package_dir <- file.path(out_dir, "package")
package_data_dir <- file.path(package_dir, "Data")
package_image_dir <- file.path(package_dir, "Image")
asset_dir <- file.path(out_dir, "assets")
client_overview_image <- "client_dashboard_overview.png"
twb_name <- "Marketplace_Revenue_Risk_Dashboard.twb"
twbx_name <- "Marketplace_Revenue_Risk_Dashboard.twbx"

if (dir.exists(package_dir)) {
  unlink(package_dir, recursive = TRUE)
}
dir.create(package_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

csv_files <- c(
  "kpi_summary.csv",
  "monthly_revenue.csv",
  "state_revenue.csv",
  "customer_decile_summary.csv",
  "customer_lorenz_curve.csv",
  "payment_summary.csv",
  "installment_distribution.csv",
  "action_plan.csv"
)

for (file in csv_files) {
  file.copy(file.path(data_dir, file), file.path(package_data_dir, file), overwrite = TRUE)
}

has_client_overview_image <- file.exists(file.path(asset_dir, client_overview_image))
if (has_client_overview_image) {
  dir.create(package_image_dir, recursive = TRUE, showWarnings = FALSE)
  file.copy(
    file.path(asset_dir, client_overview_image),
    file.path(package_image_dir, client_overview_image),
    overwrite = TRUE
  )
} else {
  warning("Client overview image not found; Tableau workbook will be built without the image-first dashboard.")
}

xml_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  x <- gsub("'", "&apos;", x, fixed = TRUE)
  x
}

field_ref <- function(ds, field) {
  paste0("[", ds, "].[", field, "]")
}

instance_name <- function(field, derivation, type_code) {
  paste0("[", tolower(derivation), ":", field, ":", type_code, "]")
}

infer_tableau_type <- function(values, field) {
  if (field == "month") {
    return(list(datatype = "date", role = "dimension", type = "ordinal", code = "ok"))
  }
  if (all(is.na(values) | grepl("^-?[0-9]+$", values))) {
    return(list(datatype = "integer", role = "measure", type = "quantitative", code = "qk"))
  }
  numeric_values <- suppressWarnings(as.numeric(values))
  if (all(is.na(values) | !is.na(numeric_values))) {
    return(list(datatype = "real", role = "measure", type = "quantitative", code = "qk"))
  }
  list(datatype = "string", role = "dimension", type = "nominal", code = "nk")
}

datasource_defs <- list()
for (file in csv_files) {
  name <- sub("\\.csv$", "", file)
  data <- read.csv(file.path(data_dir, file), check.names = FALSE)
  fields <- names(data)
  field_defs <- lapply(fields, function(field) {
    values <- as.character(data[[field]])
    type <- infer_tableau_type(values, field)
    c(list(name = field), type)
  })
  datasource_defs[[name]] <- list(file = file, name = name, fields = field_defs)
}

make_datasource <- function(def) {
  ds <- def$name
  file <- def$file
  relation_name <- sub("\\.csv$", "#csv", file)
  column_lines <- unlist(lapply(seq_along(def$fields), function(i) {
    f <- def$fields[[i]]
    sprintf(
      "            <column datatype='%s' name='%s' ordinal='%s' />",
      f$datatype,
      xml_escape(f$name),
      i - 1
    )
  }))
  top_columns <- unlist(lapply(def$fields, function(f) {
    sprintf(
      "      <column datatype='%s' name='[%s]' role='%s' type='%s' />",
      f$datatype,
      xml_escape(f$name),
      f$role,
      f$type
    )
  }))
  paste(
    sprintf("    <datasource caption='%s' inline='true' name='%s' version='18.1'>", xml_escape(ds), xml_escape(ds)),
    "      <connection class='federated'>",
    "        <named-connections>",
    sprintf("          <named-connection caption='%s' name='%s_conn'>", xml_escape(ds), xml_escape(ds)),
    sprintf("            <connection class='textscan' directory='Data' filename='%s' password='' server='' />", xml_escape(file)),
    "          </named-connection>",
    "        </named-connections>",
    sprintf("        <relation connection='%s_conn' name='%s' table='[%s]' type='table'>", xml_escape(ds), xml_escape(file), xml_escape(relation_name)),
    "          <columns character-set='UTF-8' header='yes' locale='en_US' separator=',' text-qualifier='&quot;'>",
    paste(column_lines, collapse = "\n"),
    "          </columns>",
    "        </relation>",
    "        <metadata-records>",
    "          <metadata-record class='capability'>",
    "            <remote-name>Capabilities</remote-name>",
    "          </metadata-record>",
    "        </metadata-records>",
    "      </connection>",
    "      <aliases enabled='yes' />",
    paste(top_columns, collapse = "\n"),
    "    </datasource>",
    sep = "\n"
  )
}

column_xml <- function(field, datatype, role, type) {
  sprintf(
    "            <column datatype='%s' name='[%s]' role='%s' type='%s' />",
    datatype,
    xml_escape(field),
    role,
    type
  )
}

column_instance_xml <- function(field, derivation, type_code, type) {
  sprintf(
    "            <column-instance column='[%s]' derivation='%s' name='%s' pivot='key' type='%s' />",
    xml_escape(field),
    derivation,
    xml_escape(instance_name(field, derivation, type_code)),
    type
  )
}

make_sheet <- function(name, ds, mark, rows, cols, encodings, tooltip = NULL, title = NULL) {
  deps <- c()
  used_fields <- unique(unlist(regmatches(
    paste(rows, cols, paste(encodings, collapse = " "), tooltip, sep = " "),
    gregexpr("\\[[A-Za-z0-9_]+\\]", paste(rows, cols, paste(encodings, collapse = " "), tooltip, sep = " "))
  )))
  used_fields <- gsub("^\\[|\\]$", "", used_fields)
  used_fields <- used_fields[used_fields %in% names(read.csv(file.path(data_dir, paste0(ds, ".csv")), check.names = FALSE))]
  data <- read.csv(file.path(data_dir, paste0(ds, ".csv")), check.names = FALSE)
  for (field in used_fields) {
    type <- infer_tableau_type(as.character(data[[field]]), field)
    deps <- c(deps, column_xml(field, type$datatype, type$role, type$type))
    if (type$role == "measure") {
      deps <- c(deps, column_instance_xml(field, "Sum", "qk", "quantitative"))
    } else {
      deps <- c(deps, column_instance_xml(field, "None", type$code, type$type))
    }
  }
  layout <- if (!is.null(title)) {
    paste(
      "      <layout-options>",
      "        <title>",
      "          <formatted-text>",
      sprintf("            <run bold='true' fontcolor='#17212b' fontsize='12'>%s</run>", xml_escape(title)),
      "          </formatted-text>",
      "        </title>",
      "      </layout-options>",
      sep = "\n"
    )
  } else {
    ""
  }
  tooltip_block <- if (!is.null(tooltip)) {
    paste(
      "            <customized-tooltip>",
      "              <formatted-text>",
      sprintf("                <run>%s</run>", xml_escape(tooltip)),
      "              </formatted-text>",
      "            </customized-tooltip>",
      sep = "\n"
    )
  } else {
    "            <customized-tooltip show-buttons='false'><formatted-text /></customized-tooltip>"
  }
  paste(
    sprintf("    <worksheet name='%s'>", xml_escape(name)),
    layout,
    "      <table>",
    "        <view>",
    "          <datasources>",
    sprintf("            <datasource caption='%s' name='%s' />", xml_escape(ds), xml_escape(ds)),
    "          </datasources>",
    sprintf("          <datasource-dependencies datasource='%s'>", xml_escape(ds)),
    paste(deps, collapse = "\n"),
    "          </datasource-dependencies>",
    "          <aggregation value='true' />",
    "        </view>",
    "        <style>",
    "          <style-rule element='worksheet'>",
    "            <format attr='font-family' value='Arial' />",
    "            <format attr='font-size' value='10' />",
    "          </style-rule>",
    "          <style-rule element='mark'>",
    "            <format attr='mark-labels-show' value='true' />",
    "          </style-rule>",
    "        </style>",
    "        <panes>",
    "          <pane>",
    "            <view><breakdown value='auto' /></view>",
    sprintf("            <mark class='%s' />", xml_escape(mark)),
    "            <encodings>",
    paste(encodings, collapse = "\n"),
    "            </encodings>",
    tooltip_block,
    "          </pane>",
    "        </panes>",
    sprintf("        <rows>%s</rows>", rows),
    sprintf("        <cols>%s</cols>", cols),
    "      </table>",
    "    </worksheet>",
    sep = "\n"
  )
}

ref <- function(ds, field, derivation = NULL) {
  data <- read.csv(file.path(data_dir, paste0(ds, ".csv")), check.names = FALSE)
  type <- infer_tableau_type(as.character(data[[field]]), field)
  if (is.null(derivation)) {
    if (type$role == "measure") {
      derivation <- "Sum"
    } else {
      derivation <- "None"
    }
  }
  code <- if (derivation == "Sum") "qk" else type$code
  paste0("[", ds, "].", instance_name(field, derivation, code))
}

raw_ref <- function(ds, field) {
  paste0("[", ds, "].[", field, "]")
}

enc <- function(kind, column) {
  sprintf("              <%s column='%s' />", kind, xml_escape(column))
}

sheets <- c(
  make_sheet(
    "KPI Cards", "kpi_summary", "Text",
    rows = raw_ref("kpi_summary", "risk_dimension"),
    cols = "",
    encodings = c(
      enc("text", ref("kpi_summary", "display_value", "None")),
      enc("tooltip", ref("kpi_summary", "client_explanation", "None")),
      enc("tooltip", ref("kpi_summary", "recommended_action", "None")),
      enc("color", ref("kpi_summary", "risk_level", "None"))
    ),
    title = "Executive KPI Cards"
  ),
  make_sheet(
    "Risk Priority Map", "kpi_summary", "Bar",
    rows = raw_ref("kpi_summary", "risk_dimension"),
    cols = ref("kpi_summary", "sort_order"),
    encodings = c(enc("color", ref("kpi_summary", "risk_level", "None")), enc("text", ref("kpi_summary", "sort_order"))),
    title = "Risk Priority Map"
  ),
  make_sheet(
    "Monthly Revenue Trend", "monthly_revenue", "Line",
    rows = ref("monthly_revenue", "monthly_revenue"),
    cols = raw_ref("monthly_revenue", "month"),
    encodings = c(enc("tooltip", ref("monthly_revenue", "volatility_signal", "None"))),
    title = "Monthly Revenue Trend"
  ),
  make_sheet(
    "MoM Growth", "monthly_revenue", "Bar",
    rows = ref("monthly_revenue", "mom_growth"),
    cols = raw_ref("monthly_revenue", "month"),
    encodings = c(enc("color", ref("monthly_revenue", "growth_direction", "None")), enc("tooltip", ref("monthly_revenue", "volatility_signal", "None"))),
    title = "Month-over-Month Growth"
  ),
  make_sheet(
    "Revenue Share by State", "state_revenue", "Bar",
    rows = raw_ref("state_revenue", "customer_state"),
    cols = ref("state_revenue", "revenue_share"),
    encodings = c(enc("color", ref("state_revenue", "concentration_tier", "None")), enc("text", ref("state_revenue", "revenue_share"))),
    title = "Revenue Share by State"
  ),
  make_sheet(
    "Customer Decile Revenue", "customer_decile_summary", "Bar",
    rows = ref("customer_decile_summary", "revenue_share"),
    cols = raw_ref("customer_decile_summary", "decile"),
    encodings = c(enc("text", ref("customer_decile_summary", "revenue_share"))),
    title = "Customer Revenue by Decile"
  ),
  make_sheet(
    "Customer Lorenz Curve", "customer_lorenz_curve", "Line",
    rows = ref("customer_lorenz_curve", "cumulative_revenue_share"),
    cols = ref("customer_lorenz_curve", "cumulative_customer_share"),
    encodings = c(enc("tooltip", ref("customer_lorenz_curve", "cumulative_revenue_share"))),
    title = "Lorenz Curve of Customer Revenue"
  ),
  make_sheet(
    "Payment Structure", "payment_summary", "Bar",
    rows = raw_ref("payment_summary", "payment_structure"),
    cols = ref("payment_summary", "revenue_share"),
    encodings = c(enc("color", ref("payment_summary", "payment_structure", "None")), enc("text", ref("payment_summary", "revenue_share"))),
    title = "Revenue by Payment Structure"
  ),
  make_sheet(
    "Installment Distribution", "installment_distribution", "Bar",
    rows = ref("installment_distribution", "revenue_share"),
    cols = raw_ref("installment_distribution", "max_installments"),
    encodings = c(enc("text", ref("installment_distribution", "revenue_share"))),
    title = "Installment Count Distribution"
  ),
  make_sheet(
    "Action Plan", "action_plan", "Text",
    rows = paste(raw_ref("action_plan", "priority"), raw_ref("action_plan", "action_area"), sep = " / "),
    cols = "",
    encodings = c(enc("text", ref("action_plan", "suggested_intervention", "None")), enc("tooltip", ref("action_plan", "success_metric", "None"))),
    title = "Recommended Management Actions"
  )
)

make_dashboard <- function(name, zones) {
  zone_lines <- c()
  zone_id <- 10
  for (z in zones) {
    zone_lines <- c(zone_lines, sprintf(
      "          <zone h='%d' id='%d' name='%s' show-title='true' w='%d' x='%d' y='%d' />",
      z$h, zone_id, xml_escape(z$name), z$w, z$x, z$y
    ))
    zone_id <- zone_id + 1
  }
  paste(
    sprintf("    <dashboard name='%s'>", xml_escape(name)),
    "      <layout-options>",
    "        <title><formatted-text>",
    sprintf("          <run bold='true' fontcolor='#17212b' fontsize='16'>%s</run>", xml_escape(name)),
    "        </formatted-text></title>",
    "      </layout-options>",
    "      <size maxheight='850' maxwidth='1200' minheight='850' minwidth='1200' />",
    "      <zones>",
    "        <zone h='100000' id='1' type='layout-basic' w='100000' x='0' y='0'>",
    "          <zone h='5000' id='2' type='title' w='100000' x='0' y='0' />",
    paste(zone_lines, collapse = "\n"),
    "        </zone>",
    "      </zones>",
    "    </dashboard>",
    sep = "\n"
  )
}

make_client_overview_dashboard <- function() {
  image_path <- file.path("Image", client_overview_image)
  paste(
    "    <dashboard name='Client Overview'>",
    "      <style />",
    "      <size maxheight='800' maxwidth='1000' minheight='800' minwidth='1000' />",
    "      <zones>",
    "        <zone h='100000' id='4' type-v2='layout-basic' w='100000' x='0' y='0'>",
    sprintf("          <zone alt-text='Client-friendly overview of marketplace revenue risk dashboard' h='98000' id='3' is-scaled='1' param='%s' type-v2='bitmap' w='98400' x='800' y='1000'>", xml_escape(image_path)),
    "            <zone-style>",
    "              <format attr='border-color' value='#000000' />",
    "              <format attr='border-style' value='none' />",
    "              <format attr='border-width' value='0' />",
    "              <format attr='margin' value='4' />",
    "            </zone-style>",
    "          </zone>",
    "          <zone-style>",
    "            <format attr='border-color' value='#000000' />",
    "            <format attr='border-style' value='none' />",
    "            <format attr='border-width' value='0' />",
    "            <format attr='margin' value='8' />",
    "          </zone-style>",
    "        </zone>",
    "      </zones>",
    "    </dashboard>",
    sep = "\n"
  )
}

dashboards <- c(
  if (has_client_overview_image) make_client_overview_dashboard(),
  make_dashboard("Executive Risk Overview", list(
    list(name = "KPI Cards", x = 0, y = 6000, w = 100000, h = 33000),
    list(name = "Risk Priority Map", x = 0, y = 41000, w = 56000, h = 57000),
    list(name = "Action Plan", x = 58000, y = 41000, w = 42000, h = 57000)
  )),
  make_dashboard("Revenue Stability", list(
    list(name = "Monthly Revenue Trend", x = 0, y = 6000, w = 100000, h = 45000),
    list(name = "MoM Growth", x = 0, y = 52000, w = 100000, h = 46000)
  )),
  make_dashboard("Concentration Risk", list(
    list(name = "Revenue Share by State", x = 0, y = 6000, w = 52000, h = 56000),
    list(name = "Customer Decile Revenue", x = 54000, y = 6000, w = 46000, h = 56000),
    list(name = "Customer Lorenz Curve", x = 0, y = 64000, w = 100000, h = 34000)
  )),
  make_dashboard("Liquidity & Action Plan", list(
    list(name = "Payment Structure", x = 0, y = 6000, w = 48000, h = 43000),
    list(name = "Installment Distribution", x = 50000, y = 6000, w = 50000, h = 43000),
    list(name = "Action Plan", x = 0, y = 52000, w = 100000, h = 46000)
  ))
)

worksheet_windows <- paste(sprintf(
  "    <window class='worksheet' name='%s'><cards><edge name='left'><strip size='160'><card type='pages' /><card type='filters' /><card type='marks' /></strip></edge><edge name='top'><strip size='31'><card type='columns' /></strip><strip size='31'><card type='rows' /></strip><strip size='31'><card type='title' /></strip></edge></cards></window>",
  xml_escape(c("KPI Cards", "Risk Priority Map", "Monthly Revenue Trend", "MoM Growth", "Revenue Share by State", "Customer Decile Revenue", "Customer Lorenz Curve", "Payment Structure", "Installment Distribution", "Action Plan"))
), collapse = "\n")

dashboard_windows <- paste(sprintf(
  "    <window class='dashboard' maximized='true' name='%s'><viewpoints>%s</viewpoints><active id='-1' /></window>",
  xml_escape(c(
    if (has_client_overview_image) "Client Overview",
    "Liquidity & Action Plan",
    "Concentration Risk",
    "Revenue Stability",
    "Executive Risk Overview"
  )),
  c(
    if (has_client_overview_image) "",
    "<viewpoint name='Payment Structure' /><viewpoint name='Installment Distribution' /><viewpoint name='Action Plan' />"
    ,
    "<viewpoint name='Revenue Share by State' /><viewpoint name='Customer Decile Revenue' /><viewpoint name='Customer Lorenz Curve' />",
    "<viewpoint name='Monthly Revenue Trend' /><viewpoint name='MoM Growth' />",
    "<viewpoint name='KPI Cards' /><viewpoint name='Risk Priority Map' /><viewpoint name='Action Plan' />"
  )
), collapse = "\n")

workbook <- paste(
  "<?xml version='1.0' encoding='utf-8' ?>",
  "<workbook locale='en_US' source-build='2026.1.0' source-platform='mac' version='18.1' xmlns:user='http://www.tableausoftware.com/xml/user'>",
  "  <preferences>",
  "    <preference name='ui.encoding.shelf.height' value='24' />",
  "    <preference name='ui.shelf.height' value='26' />",
  "  </preferences>",
  "  <style-theme name='smooth' />",
  "  <datasources>",
  paste(vapply(datasource_defs, make_datasource, character(1)), collapse = "\n"),
  "  </datasources>",
  "  <worksheets>",
  paste(sheets, collapse = "\n"),
  "  </worksheets>",
  "  <dashboards>",
  paste(dashboards, collapse = "\n"),
  "  </dashboards>",
  "  <windows source-height='32'>",
  dashboard_windows,
  worksheet_windows,
  "  </windows>",
  "</workbook>",
  sep = "\n"
)

writeLines(workbook, file.path(package_dir, twb_name), useBytes = TRUE)

old_wd <- getwd()
setwd(package_dir)
if (file.exists(file.path("..", twbx_name))) {
  unlink(file.path("..", twbx_name))
}
zip_contents <- c(twb_name, "Data")
if (has_client_overview_image) {
  zip_contents <- c(zip_contents, "Image")
}
zip::zipr(file.path("..", twbx_name), zip_contents)
setwd(old_wd)

file.copy(file.path(package_dir, twb_name), file.path(out_dir, twb_name), overwrite = TRUE)
unlink(package_dir, recursive = TRUE)

message("Built Tableau workbook: ", normalizePath(file.path(out_dir, twbx_name)))
