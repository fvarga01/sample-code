from typing import List, Optional
from collections import defaultdict
import time

class ListNode:
	def __init__(self, val:0, next=None) -> None:
		self.val=val
		self.next=next
def main():
	sol=Solution()
	#res=sol.minWindowSubstring(s = "abcdec", t = "acc")
	#res=sol.minWindowSubstring(s = "a", t = "a")
	#res=sol.minWindowSubstring(s = "a", t = "aa")
	#res=sol.minWindowSubstring(s = "bdab", t = "ab") # hangs
	#res=sol.minWindowSubstring(s = "AADOBECODEBANC", t = "ABC")
	res=sol.intToRoman(41)
	print(res)
	#expected output should be "ab", but returning "bda"
class Solution:
	def intToRoman(self, num: int) -> str:
		i_to_r_map = {1000:'M', 500:'D', 100:'C', 50:'L', 10:'X', 5:'V', 1:'I' }
		roman_str=""
		for key,value in i_to_r_map.items():
			num=num%key
			print(key, value, num)

	def minWindowSubstring(self, s: str, t: str) -> str:
		len_s, len_t=len(s), len(t)
		# s_found=list(map(lambda x: x if x in t else "" ,s))

 		# Initialize a hashtable to store the frequency of each character in t
		# Alternate approach: t_map=defaultdict(int) # list(map(lambda x: t_map.update({x: t_map[x] + 1}), t))
		t_map={}
		for c in t: t_map[c] = t_map.get(c,0) +1

		# Initialize variables to keep track of the minimum window
		min_window_len=len_s # Start with the maximum possible length
		min_substring="" # To store the minimum window substring
		i_start=0 # Left boundary of the window
		i_end=0 # Right boundary of the window
		total_matched_substring_ctr=0 # Counter for characters matched in t

		# Initialize a hashtable to keep track of the frequency of characters in the current window
		s_window_map={}
		
		# Expansion loop: move the end pointer to the right for each character
		while i_end < len_s:
			# Current character being checked
			c_end = s[i_end]
			# If the current character is not in t, just move the pointer to the next character
			if c_end not in t_map: 
				i_end +=1
				continue
			# Add to the count of the current found character
			s_window_map[ c_end ] = s_window_map.get(c_end,0) + 1
			 # Increase total count if we haven't reached the required number of counts for this character
			if(s_window_map[c_end] <= t_map[c_end]): total_matched_substring_ctr +=1
			# If all characters in t are found
			if (total_matched_substring_ctr == len_t):
				# Check if we can optimize and move the start to make the string shorter	
				c_start=s[i_start] 			
				# Minimize the window size by removing unnecessary characters from the left side of the window
				# but still maintain all required characters with their correct frequencies
				while c_start not in t_map or s_window_map[c_start] > t_map[ c_start]:
					if c_start in t_map:
						s_window_map.update( {c_start: s_window_map[c_start] - 1 } )  #Decrease the count for this character
					i_start +=1
					c_start=s[i_start]
					# print("dbg-1 shortened  %s from left to %s %s" %(s[i_start-1: i_end+1], s[i_start: i_end+1], s_window_map))
				# Re-calculate the minimum window
				window_len=i_end-i_start+1
				if min_window_len >= window_len:
					min_window_len = window_len
					min_substring = s[i_start: i_end+1]
				# Optimization: if we are sure we cannot find a shorter string, just exit now
				if(min_window_len == len_t): break
				# print("dbg-2 current matched substring:%s, min_substring:%s, map: %s\n" %(s[i_start: i_end+1], min_substring,  s_window_map))
			i_end +=1
		return min_substring
	def addTwoNumbers(self, l1: ListNode, l2: ListNode) -> ListNode:
		dummyHead = ListNode(0)
		current = dummyHead
		carry = 0
		while l1 or l2 or carry:
			# Get values from the current nodes, or 0 if the node is None
			print("carry from prev: ", carry)
			val1 = l1.val if l1 else 0
			val2 = l2.val if l2 else 0
			# Calculate the sum and the new carry
			total = val1 + val2 + carry
			carry = total // 10
			print(val1, " ", val2, "--", carry, " ", total)
			new_digit = total % 10
			print("digit:", new_digit)
			# Create a new node with the new digit and attach it to the result list
			current.next = ListNode(new_digit)
			current = current.next
			# Move to the next nodes in l1 and l2 if they exist
			l1 = l1.next if l1 else None
			l2 = l2.next if l2 else None
		return dummyHead.next
	def containsDuplicateWithSet(self, nums: List[int]) -> bool:
		seen = set()
		for num in nums:
			if num in seen:
				return True
		seen.add(num)
		return False
	def containsDuplicate(self, nums:List[int]) -> bool:
		print(nums)
		nums.sort()
		print(nums)
		for i in range(1,len(nums)):
			if nums[i]==nums[i-1]:
				return True
		return False
	def removeElement(self, nums: List[int], val: int) -> int:
		idx=0
		for i in range(len(nums)):
			if(nums[i]!=val):
				nums[idx]=nums[i]
				idx+=1
			else:
				nums[idx]='-'
				nums[i]='-'
		print(nums)
		return idx
	def maxSubArray(self, nums:List) -> int:
		runningSum=maxSum=nums[0]
		for i in range(1, len(nums)):
			runningSum = max(runningSum+nums[i], nums[i])#max because will discard running sum if its lower than just current element by itself
			maxSum=max(runningSum, maxSum)
			print(i, " ", nums[i], " " , runningSum, " ", maxSum)
		return maxSum
	def isPalindrome(self, x: int) -> bool:
		tmp=x
		reversed_num=0
		while(tmp > 0):
			lowest_digit=tmp%10 #extract lowest digit: 123->3
			tmp=int((tmp-lowest_digit)/10) #new number without lowest digit: 123->12
			#tmp=int(tmp/10)#new number without lowest digit: 123->12
			reversed_num=reversed_num*10+lowest_digit
			print("x=", x, " lowest_digit=", lowest_digit, " tmp=", tmp, " reversed_num=", reversed_num)
		return reversed_num==x
	def twoSum(self, nums: List[int], target: int) -> List[int]:
		ctr=0
		nums_len=len(nums)
		out_arr=[]
		for i in range(nums_len):
			for j in range(i+1,nums_len):
				ctr=nums[i]+nums[j]
				print(nums_len, " ", i, " " , j," ", ctr)
				if(ctr==target):
					out_arr.append(i)
					out_arr.append(j)
		return out_arr
	def twoSumWithHashMap2(self, nums: List[int], target: int) -> List[int]:
		numMap = {}
		n = len(nums)
		for i in range(n):
			complement = target - nums[i]
			print(i, " ", complement, " ", numMap)
			if complement in numMap:
				return [numMap[complement], i]
			numMap[nums[i]] = i
		return []  # No solution found
def list_to_linkedlist(lst):
	dummyHead = ListNode(0)
	current = dummyHead
	for value in lst:
		current.next = ListNode(value)
		current = current.next
	return dummyHead.next
def print_linked_list(node):
    while node:
        print(node.val, end=" -> ")
        node = node.next
    print("None")
def main_old():
	print('old main')
	# Linked List solution: 
	# sol=Solution()
	# l1 = list_to_linkedlist([2, 4, 3])
	# l2 = list_to_linkedlist([5, 6, 4])
	# res=sol.addTwoNumbers(l1,l2)
	# print_linked_list(res)
	# end Linked List solution

	# res=sol.twoSum([3,2,3],6)
	# res=sol.twoSumWithHashMap([3,2,3],6)
	#res=sol.isPalindrome(0)
	# res = sol.maxSubArray([-2,1,-3,4,-1,2,1,-5,4])
	#res=sol.removeElement([3,2,2,4,5,3],3)
	# res=sol.containsDuplicate([0,1,2,6,3,2])
if __name__ == '__main__':
	main()