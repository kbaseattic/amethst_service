module AMETHSTService {
/* last parameter "tree" is optional
*/

funcdef amethst(string abundance_matrix, string groups_list, string commands_list, string tree) returns (string job_id);
funcdef status(string job_id) returns (string status)  ;
funcdef results(string job_id) returns (mapping<string, string>);
funcdef delete_job(string job_id) returns (string results);
};
