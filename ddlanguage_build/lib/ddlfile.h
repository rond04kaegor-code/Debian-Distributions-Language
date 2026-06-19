#ifndef DDLFILE_H
#define DDLFILE_H
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
namespace ddl {
class File {
public:
    static bool exists(const std::string& p){struct stat b;return stat(p.c_str(),&b)==0;}
    static long size(const std::string& p){struct stat b;if(stat(p.c_str(),&b)!=0)return-1;return b.st_size;}
    static std::string read_all(const std::string& p){std::ifstream f(p);if(!f.is_open())return"";std::stringstream b;b<<f.rdbuf();return b.str();}
    static std::vector<std::string> read_lines(const std::string& p){std::vector<std::string> l;std::ifstream f(p);std::string ln;while(std::getline(f,ln))l.push_back(ln);return l;}
    static void write_all(const std::string& p,const std::string& c){std::ofstream f(p);f<<c;}
    static std::vector<std::string> list_dir(const std::string& p){std::vector<std::string> e;DIR* d=opendir(p.c_str());if(!d)return e;struct dirent* en;while((en=readdir(d))!=NULL){std::string n=en->d_name;if(n!="."&&n!="..")e.push_back(n);}closedir(d);return e;}
    static bool create_dir(const std::string& p){return mkdir(p.c_str(),0755)==0;}
    static bool remove(const std::string& p){return std::remove(p.c_str())==0;}
};
inline bool file_exists(const std::string& p){return File::exists(p);}
inline std::string read_file(const std::string& p){return File::read_all(p);}
inline void write_file(const std::string& p,const std::string& c){File::write_all(p,c);}
}
#endif
