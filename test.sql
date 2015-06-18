#include "stdafx.h"

#using <System.dll>
#using <System.Data.dll>
#using <System.Xml.dll>

using namespace System;
using namespace System::Data;
using namespace System::Data::Sql;
using namespace System::Data::SqlClient;
using namespace System::Data::SqlTypes;
using namespace System::Text::RegularExpressions;
using namespace Microsoft::SqlServer::Server;

// In order to debug your Trigger, add the following to your debug.sql file: 
// 
// -- Insert one user name that is not an e-mail address and one that is 
// INSERT INTO Users(UserName, Pass) VALUES(N'someone', N'cnffjbeq') 
// INSERT INTO Users(UserName, Pass) VALUES(N'someone@example.com', N'cnffjbeq') 
// 
// -- check the Users and UsersAudit tables to see the results of the trigger 
// SELECT * FROM Users 
// SELECT * FROM UsersAudit 
// 

public ref class AddNewTrigger
{
public:
    [SqlTrigger(Name="UserNameAudit", Target="Users", Event="FOR INSERT")]
    static void UserNameAudit()
    {
        SqlTriggerContext ^triggContext = SqlContext::TriggerContext;
        SqlParameter ^userName = gcnew SqlParameter("@username", System::Data::SqlDbType::NVarChar);

        if (triggContext->TriggerAction == TriggerAction::Insert)
        {
            SqlConnection ^conn = gcnew SqlConnection("context connection=true");
            conn->Open();
            SqlCommand ^sqlComm = gcnew SqlCommand();
            SqlPipe ^sqlP = SqlContext::Pipe;

            sqlComm->Connection = conn;
            sqlComm->CommandText = "SELECT UserName from INSERTED";

            userName->Value = sqlComm->ExecuteScalar()->ToString();

            if (IsEMailAddress(userName->ToString()))
            {
                sqlComm->CommandText = "INSERT UsersAudit(UserName) VALUES(userName)";
                sqlP->Send(sqlComm->CommandText);
                sqlP->ExecuteAndSend(sqlComm);
            }

            conn->Close();
        }
    }

    static bool IsEMailAddress(String ^s)
    {
        return Regex::IsMatch(s, "^([\\w-]+\\.)*?[\\w-]+@[\\w-]+\\.([\\w-]+\\.)*?[\\w]+$");
    }
};