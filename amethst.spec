module AMETHSTService {
/* last parameter "tree" is optional
*/

authentication optional;
funcdef amethst(string commands_list, mapping<string, string> file2shock) returns (string job_id);

authentication optional;
funcdef status(string job_id) returns (string status);

authentication optional;
funcdef results(string job_id) returns (mapping<string, string>);

authentication optional;
funcdef delete_job(string job_id, string shocktoken) returns (string results);
};
