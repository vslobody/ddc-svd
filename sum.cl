#ifdef cl_khr_fp64
    #pragma OPENCL EXTENSION cl_khr_fp64 : enable
#elif defined(cl_amd_fp64)
    #pragma OPENCL EXTENSION cl_amd_fp64 : enable
#else
    #error "Double precision floating point not supported by OpenCL implementation."
#endif

/**********************************************************
 * kernel: sum
 * 
 * Original Author: Travis Askham (12/20/2012)
 * 
 * Description: This kernel is used as part of a reduction operation on
 * the input vector vec. It has each work item sum up work_per_item
 * consecutive entries and then does the reduction on the whole group
 * it then writes out the total sum for the group to the scratch vector
 * at position gi+write_offset = get_group_id(0)+write_offset.
 * 
 * Input: as above, and n is the length of the vector vec. 
 * 
 **********************************************************/

__kernel void sum(
    __global const double * vec, __global double *scratch,
    unsigned int n, unsigned int work_per_item, int write_offset )
{
	// find local work group dimensions and location
	int gdim0 = get_local_size(0);
	int li = get_local_id(0);
	int gi = get_group_id(0);
	int si = (gi*gdim0+li)*work_per_item;
	int sl = li*work_per_item;
	int comp = n-si;

	__local double loc [LOC_SIZE];

	for (int i=0; i < work_per_item; i++){
		loc[sl+i] = (i < comp) ? vec[si+i] : 0;
	}
	
	double s = 0;
	
	for (int i=0; i < work_per_item; i++){
		s += loc[sl+i];
	}
	
	barrier(CLK_LOCAL_MEM_FENCE);
	
	loc[li] = s;
	
	barrier(CLK_LOCAL_MEM_FENCE);
	
	for (int i=gdim0/2; i>0; i>>=1){
		if (li < i){
			loc[li] += loc[li+i];
		}
		barrier(CLK_LOCAL_MEM_FENCE);
	}

	// write to scratch
	if (li == 0)
		scratch[gi+write_offset] = loc[0];


}
