#ifndef DDLDATABASE_H
#define DDLDATABASE_H
#include <sqlite3.h>
#include <string>
namespace ddl {
class Database {
    sqlite3* db;
public:
    Database(const std::string& p):db(nullptr){sqlite3_open(p.c_str(),&db);if(db)sqlite3_exec(db,"CREATE TABLE IF NOT EXISTS kv_store(key TEXT PRIMARY KEY,value TEXT)",NULL,NULL,NULL);}
    ~Database(){if(db)sqlite3_close(db);}
    void set(const std::string& k,const std::string& v){if(!db)return;std::string s="INSERT OR REPLACE INTO kv_store VALUES('"+k+"','"+v+"')";sqlite3_exec(db,s.c_str(),NULL,NULL,NULL);}
    std::string get(const std::string& k,const std::string& d=""){if(!db)return d;sqlite3_stmt* st;std::string s="SELECT value FROM kv_store WHERE key='"+k+"'";if(sqlite3_prepare_v2(db,s.c_str(),-1,&st,NULL)!=SQLITE_OK)return d;std::string r=d;if(sqlite3_step(st)==SQLITE_ROW){const char* v=(const char*)sqlite3_column_text(st,0);if(v)r=v;}sqlite3_finalize(st);return r;}
};
inline Database* db_open(const std::string& p){return new Database(p);}
}
#endif
