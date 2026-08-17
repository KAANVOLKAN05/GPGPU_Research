data = load("-struct", "data_file.mat");
% Access variables as fields of the structure
mua_list = data.mua_list
values_list = data.values_list
normalized_MCX = data.normalized_MCX
theory = data.theory
log_error = data.log_error
RMSE_log = data.RMSE_log
save('AbsorptionTestResults.mat','mua_list', 'values_list', 'normalized_MCX','theory', 'log_error', 'RMSE_log');

