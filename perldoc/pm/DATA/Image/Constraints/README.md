# DATA::Image::Constraints

Constraints applied to an image referenced by its URL, i.e. the validated value
is the URL of the image. These can be applied to an image that's either hosted
 on our own site or hosted externally.

## Constraints

### image\_valid

Effectively tests three things:
1\. That the URL given corresponds to a valid location - returns HTTP 200;
2\. That an image object of a valid image MIME type is retrieved;
3\. That the image does not exceed the file limit.
