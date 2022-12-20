# Clinical-Recommender-System



## Order of the Notebooks to Run (Dec 2022 Update):
Have the train and test data ready.

1- Run Model_1_Deep.ipynb (this is used in the proposed model)
2- Run all Model_2_*.ipynb
* Model_2_CF_AE.ipynb is used in the proposed model and the rest of the models are those we compare the proposed model with)
* Note that Model_2_NMF.ipynb has an error, but you can exclude that from the analysis.
3- Run Unit_Deep_model.ipynb (this is one of the models that we compare the proposed model with)
4- Run Model_ensemble.ipynb and Model_ensemble_w_prov_id.ipynb
* Note that Model_ensemble_w_prov_id.ipynb uses the provider ids as additional data.
5- Run evaluate_all.ipynb to plot the results
* Note that when running the plot the output of the ensemble_model was not as we got in the paper. It needs some debugging.





## Steps to pre-process the data and train the model (2020 note):



1- Run SQL queries to separately extract PCP lab results, diagnosis, procedures and Specialty procedures

2- Run the Jupiter notebooks to filter the features to include only top N results, and then create the features matrix per PCP encounter id

3- Run join_tables to create a table containing all tables and create train and test tables (two separate csv files)

4- Prepare the data for Model 2 (collaborative filtering): Run CF_data_processing Jupiter notebook
* Note that this processing includes melting the data from feature matrix form to ratings matrix
* The training data includes procedures both from PCP (train of both PCP and Specialty and test of PCP) and Specialty (training and test of Specialty)
* The test data only includes procedures from the PCP

5- Run each of the CF models 
* The output should be a feature matrix for test encounters
* Save the output data into CF_AE_pred data frame including the encounter ids

6- Run CF_evaluation

7- Run the model 1 based on the train and test datasets created in step 3
* Turns the test data frame into numpy and feed-in the model
* Save the output data into model1_pred data frame including the encounter ids

8- Run the ensemble model (ens_model)
* Get the test data frame generated in step 3 (Only pick the specialty procedures), CF_AE_pred and model1_pred and join them sing PCP encounter
* Train the model
* save the results into final_pred dataframe

9- Evaluate the ensemble model (ens_evaluation)
* Load the final_pred dataframe and the test data frame generated in step 3 (Only pick the specialty procedures)



