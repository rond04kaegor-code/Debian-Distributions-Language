#ifndef DDLCOMPRESS_H
#define DDLCOMPRESS_H
#include <zstd.h>
#include <string>
#include <vector>
namespace ddl {
inline std::vector<char> compress(const std::string& s){size_t b=ZSTD_compressBound(s.size());std::vector<char> o(b);size_t c=ZSTD_compress(o.data(),b,s.data(),s.size(),1);o.resize(c);return o;}
inline std::string decompress(const std::vector<char>& d){size_t s=ZSTD_getFrameContentSize(d.data(),d.size());std::string o(s,'\0');ZSTD_decompress((void*)o.data(),s,d.data(),d.size());return o;}
}
#endif
