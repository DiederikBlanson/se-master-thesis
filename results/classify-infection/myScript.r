# Load packages
library(data.table)

# Read in the data
antibioticDT <- fread('antibioticDT.csv')

# Look at the first 30 rows
head(antibioticDT, 30)

# Sort the data and examine the first 40 rows
setorder(x = antibioticDT, patient_id, antibiotic_type, day_given)
antibioticDT[1:40]
# Use shift to calculate the last day a particular drug was administered
antibioticDT[ , last_administration_day := shift(day_given, n = 1, type = "lag"), 
  by = .(patient_id, antibiotic_type)]

# Calculate the number of days since the drug was last administered
antibioticDT[ , days_since_last_admin := day_given - last_administration_day]

# Create antibiotic_new with an initial value of one, then reset it to zero as needed
antibioticDT[, antibiotic_new := 1]
antibioticDT[days_since_last_admin <= 2, antibiotic_new := 0]
antibioticDT[1:40]


# Read in blood_cultureDT.csv
blood_cultureDT <- fread("blood_cultureDT.csv")

# Print the first 30 rows
blood_cultureDT[1:30]

# Merge antibioticDT with blood_cultureDT
combinedDT <- merge(antibioticDT, blood_cultureDT, by = "patient_id", all = FALSE)

# Sort by patient_id, blood_culture_day, day_given, and antibiotic_type
setorder(combinedDT, patient_id, blood_culture_day, day_given, antibiotic_type)

# Print and examine the first 30 rows
combinedDT[1:30]

# Make a new variable called drug_in_bcx_window
combinedDT[ , 
  drug_in_bcx_window := 
           as.numeric(
               day_given - blood_culture_day <= 2 
               & 
               day_given - blood_culture_day >= -2)]
combinedDT[1:5]


# Create a variable indicating if there was at least one I.V. drug given in the window
combinedDT[ , 
  any_iv_in_bcx_window := as.numeric(any(route == 'IV' & drug_in_bcx_window == 1)),
  by = .(patient_id, blood_culture_day)]
# Exclude rows in which the blood_culture_day does not have any I.V. drugs in window 
combinedDT <- combinedDT[any_iv_in_bcx_window == 1]
combinedDT[1:5]

# Create a new variable called day_of_first_new_abx_in_window
combinedDT[,
          day_of_first_new_abx_in_window := 
           day_given[antibiotic_new == 1 & drug_in_bcx_window == 1][1],
           by = .(patient_id, blood_culture_day)
          ]

# Remove rows where the day is before this first qualifying day
combinedDT <- combinedDT[day_given >= day_of_first_new_abx_in_window]
combinedDT[1:5]

# Create a new data.table containing only patient_id, blood_culture_day, and day_given
simplified_data <- combinedDT[, .(patient_id, blood_culture_day, day_given)]

# Remove duplicate rows
simplified_data <- unique(simplified_data)
simplified_data[1:5]

# Count the antibiotic days within each patient/blood culture day combination
simplified_data[, num_antibiotic_days := .N, by = .(patient_id, blood_culture_day)]

# Remove blood culture days with less than four rows 
simplified_data <- simplified_data[num_antibiotic_days >= 4]

# Select the first four days for each blood culture
first_four_days <- simplified_data[, .SD[1:4], by = .(patient_id, blood_culture_day)]
first_four_days[1:5]

# Make the indicator for consecutive sequence
first_four_days[,
               four_in_seq := as.numeric(max(diff(day_given)) < 3), by = .(patient_id, blood_culture_day)
               ]

# Select the rows which have four_in_seq equal to 1
suspected_infection <- first_four_days[four_in_seq == 1]

# Retain only the patient_id column
suspected_infection <- suspected_infection[, .(patient_id)]

# Remove duplicates
suspected_infection <- unique(suspected_infection)

# Make an infection indicator
suspected_infection[, infection := 1]
suspected_infection[1:5]

# Read in "all_patients.csv"
all_patientsDT <- fread("all_patients.csv")

# Merge this with the infection flag data
all_patientsDT <- merge(all_patientsDT, suspected_infection, all = TRUE)

# Set any missing values of the infection flag to 0
all_patientsDT <- all_patientsDT[is.na(infection), infection := 0]
all_patientsDT[1:10]
# Calculate the percentage of patients who met the criteria for presumed infection
ans  <- 100* all_patientsDT[, mean(infection)]
ans
