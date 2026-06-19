#ifndef DDLNET_H
#define DDLNET_H
#include <curl/curl.h>
#include <string>
namespace ddl {
class HTTP {
    static size_t wcb(void* c,size_t s,size_t n,std::string* o){o->append((char*)c,s*n);return s*n;}
public:
    static std::string get(const std::string& u){CURL* cu=curl_easy_init();if(!cu)return"";std::string r;curl_easy_setopt(cu,CURLOPT_URL,u.c_str());curl_easy_setopt(cu,CURLOPT_WRITEFUNCTION,wcb);curl_easy_setopt(cu,CURLOPT_WRITEDATA,&r);curl_easy_setopt(cu,CURLOPT_FOLLOWLOCATION,1L);curl_easy_perform(cu);curl_easy_cleanup(cu);return r;}
    static std::string post(const std::string& u,const std::string& d){CURL* cu=curl_easy_init();if(!cu)return"";std::string r;curl_easy_setopt(cu,CURLOPT_URL,u.c_str());curl_easy_setopt(cu,CURLOPT_POSTFIELDS,d.c_str());curl_easy_setopt(cu,CURLOPT_WRITEFUNCTION,wcb);curl_easy_setopt(cu,CURLOPT_WRITEDATA,&r);curl_easy_perform(cu);curl_easy_cleanup(cu);return r;}
};
inline std::string web_get(const std::string& u){return HTTP::get(u);}
inline std::string web_post(const std::string& u,const std::string& d){return HTTP::post(u,d);}
}
#endif
