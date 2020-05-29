using System;
using System.DirectoryServices.AccountManagement;

namespace NetCoreConsoleApp2
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Entering main");
            try
            {
                //string srvr = "contosodc";
                string srvr = "<<enter ipaddress here>>";
                string ou = null;

                //PrincipalContext _pc = new PrincipalContext(ContextType.Domain, srvr);

                PrincipalContext _pc = new PrincipalContext(
                        ContextType.Domain,
                        srvr,
                        ou,
                        ContextOptions.SimpleBind,
                        "contosoadminuser@contoso.com", "<<enter user's password here>>");

                UserPrincipal userPrincipal = UserPrincipal.FindByIdentity(_pc, IdentityType.Name, "OtherContosoADUser1");
                if (userPrincipal != null)
                {
                    Console.WriteLine("Found account: " + userPrincipal.DistinguishedName);
                }
                else { Console.WriteLine("Could not find account."); }


                /*var str = Environment.GetEnvironmentVariable("sql_connstring");
log.LogInformation("Conn string = " + str);

using (SqlConnection conn = new SqlConnection(str))
{
    conn.Open();
    var text = "Insert into t1 " +
            " values (5);";

    using (SqlCommand cmd = new SqlCommand(text, conn))
    {
        // Execute the command and log the # rows affected.
        var rows = await cmd.ExecuteNonQueryAsync();
        log.LogInformation($"{rows} rows were updated");
    }
}
*/


                Console.WriteLine("End of sample program");
                Console.ReadLine();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Caught an exception: " + ex.Message + "\n" + ex.StackTrace);
                Console.ReadLine();
            }
        }
    }
}
