module AMETHSTService {
/* last parameter "tree" is optional
*/

funcdef amethst(string commands_list, mapping<string, string> file2shock) returns (string job_id);

funcdef status(string job_id) returns (string status);
funcdef results(string job_id) returns (mapping<string, string>);
funcdef delete_job(string job_id, string shocktoken) returns (string results);
funcdef version() returns (string version);
};
