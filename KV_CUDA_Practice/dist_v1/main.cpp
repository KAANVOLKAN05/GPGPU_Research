#include <math.h>

#define N 64

float distance(float x1 , float x2)
{

	return sqrt((x2 - x1) * (x2 - x1));
}




float scale(int i, int n)
{
	return ((float)i)/(n-1);

}
int main()
{
	float out[N] = {0.0F};
	float ref = 0.5f;



	for (int i = 0; i<N; ++i)
	{


		float x = scale(i,N);
		out[i] = distance(x,ref);

	} 

return 0;
 

}    

 

 
