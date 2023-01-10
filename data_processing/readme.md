Processing data!

Steps are as follows:

* Create_PC_diagnosis.ipynb creates PC_diagnosis.csv
* Create_PC_lab_features_v3.ipynb creates PC_lab_results_v3.csv
* Create_PC_proc.ipynb creates PC_proc.csv
* Create_SP_proc_matrix_v3.ipynb creates SP_proc_v3.csv
* match_tables_v2.ipynb combines all the features from the above tables and creates data_train.csv and data_test.csv (creating train and test data)
* CF_data_processing_v2.ipynb gets creates data_train.csv and data_test.csv files and reformats them for the collaborative filtering model (from column format to the row format). Every feature in the new format will be in a separate row. The CF models get the data in this format.

