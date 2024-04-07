def mean: add / length;
def stddev: mean as $mean | (map(pow(. - $mean; 2)) | add) / length | sqrt;
