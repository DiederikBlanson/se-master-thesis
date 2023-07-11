# Importing the tidyverse library
library(tidyverse)

# Loading in datasets/users.csv 
users <- read_csv("users.csv")

# Counting how many users we've got
nrow(users)

# Taking a look at the 12 first users
head(users, n = 12)

# Calculating the lengths of users' passwords
users$length <- str_length(users$password)

# Flagging the users with too short passwords
users$too_short <- users$length < 8

# Counting the number of users with too short passwords
sum(users$too_short)

# Taking a look at the 12 first rows
head(users, n = 12)

# Reading in the top 10000 passwords
common_passwords <- read_lines("10_million_password_list_top_10000.txt")

# Taking a look at the top 100
head(common_passwords, n = 100)

# Flagging the users with passwords that are common passwords
users$common_password <- users$password %in% common_passwords

# Counting the number of users using common passwords
sum(users$common_password)

# Taking a look at the 12 first rows
head(users, n = 12)

# Reading in a list of the 10000 most common words
words <- read_lines("google-10000-english.txt")

# Flagging the users with passwords that are common words
users$common_word <- str_to_lower(users$password) %in% words

# Counting the number of users using common words as passwords
sum(users$common_word)

# Taking a look at the 12 first rows
head(users, n=12)

# Extracting first and last names into their own columns
users$first_name <- str_extract(users$user_name, "^\\w+")
users$last_name <- str_extract(users$user_name, "[^.]\\w+$")

# Flagging the users with passwords that matches their names
users$uses_name <- users$password == users$first_name | users$password == users$last_name

# Counting the number of users using names as passwords
sum(users$uses_name)

# Taking a look at the 12 first rows
head(users, n = 12)

# Splitting the passwords into vectors of single characters
split_passwords <- str_split(users$password, "")

# Picking out the max number of repeat characters for each password
users$max_repeats <- sapply(split_passwords, function(split_password) {
    max(rle(split_password)$length)
})

# Flagging the passwords with >= 4 repeats
users$too_many_repeats <- users$max_repeats >= 4

# Taking a look at the users with too many repeats
head(users)

# Flagging all passwords that are bad
users$bad_password <- users$too_short | users$common_password | users$common_word | users$uses_name | users$too_many_repeats

# Counting the number of bad passwords
sum(users$bad_password)

# Looking at the first 100 bad passwords
head(users, n = 100)

# Enter a password that passes the NIST requirements
# PLEASE DO NOT USE AN EXISTING PASSWORD HERE
new_password <- "Qwerty@357"
