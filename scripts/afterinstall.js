//This hook is used to properly package bit6 library (run ant release).
//The build mechanism for cordova app does not pacakge R file with bit6 library.
//This may be changed to a better solution later. 

var sys = require('sys')
var exec = require('child_process').exec;

function puts(error, stdout, stderr) { sys.puts(stdout) }

exec("cd platforms/android/com.bit6.sdk/bit6-sdk && ant release", puts);

