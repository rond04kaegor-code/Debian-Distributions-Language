#ifndef DDLCRYPTO_H
#define DDLCRYPTO_H
#include <openssl/sha.h>
#include <openssl/md5.h>
#include <string>
#include <sstream>
#include <iomanip>
namespace ddl {
inline std::string sha256(const std::string& s){unsigned char h[SHA256_DIGEST_LENGTH];SHA256((unsigned char*)s.c_str(),s.length(),h);std::stringstream ss;for(int i=0;i<SHA256_DIGEST_LENGTH;i++)ss<<std::hex<<std::setw(2)<<std::setfill('0')<<(int)h[i];return ss.str();}
inline std::string md5(const std::string& s){unsigned char h[MD5_DIGEST_LENGTH];MD5((unsigned char*)s.c_str(),s.length(),h);std::stringstream ss;for(int i=0;i<MD5_DIGEST_LENGTH;i++)ss<<std::hex<<std::setw(2)<<std::setfill('0')<<(int)h[i];return ss.str();}
}
#endif
