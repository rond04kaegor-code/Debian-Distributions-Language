#ifndef DDLIMAGE_H
#define DDLIMAGE_H
#include <opencv2/opencv.hpp>
#include <string>
namespace ddl {
class Image {
    cv::Mat img;
public:
    Image(){} 
    Image(const std::string& p){img=cv::imread(p);}
    bool load(const std::string& p){img=cv::imread(p);return!img.empty();}
    bool save(const std::string& p){return cv::imwrite(p,img);}
    void resize(int w,int h){cv::resize(img,img,cv::Size(w,h));}
    void gray(){cv::cvtColor(img,img,cv::COLOR_BGR2GRAY);}
    void blur(int k){cv::GaussianBlur(img,img,cv::Size(k|1,k|1),0);}
    int width(){return img.cols;}
    int height(){return img.rows;}
};
inline Image* img_open(const std::string& p){return new Image(p);}
}
#endif
