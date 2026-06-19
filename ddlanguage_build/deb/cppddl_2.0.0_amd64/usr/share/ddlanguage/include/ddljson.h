#ifndef DDLJSON_H
#define DDLJSON_H
#include <json/json.h>
#include <string>
namespace ddl {
class JSON {
    Json::Value root;
public:
    JSON(){} JSON(const std::string& s){Json::CharReaderBuilder b;std::string e;std::istringstream st(s);Json::parseFromStream(b,st,&root,&e);}
    std::string get_string(const std::string& k,const std::string& d=""){return(root.isMember(k)&&root[k].isString())?root[k].asString():d;}
    int get_int(const std::string& k,int d=0){return(root.isMember(k)&&root[k].isInt())?root[k].asInt():d;}
    std::string to_string(){Json::StreamWriterBuilder b;b["indentation"]="";return Json::writeString(b,root);}
};
inline std::string json_parse(const std::string& s,const std::string& k){JSON j(s);return j.get_string(k);}
}
#endif
