from typing import List, Optional
from collections import defaultdict, deque
import time
# from timeit import timeit

class ListNode:
	def __init__(self, val:0, next=None) -> None:
		self.val=val
		self.next=next
def main():
	sol=Solution()
	# res=sol.intToRoman(3749)
	# res=sol.twoSum([2,7,11,15],9)
	# res=sol.isValid("([(()]){}")
	# res=sol.twoSum([3,2,3],6)
	# res=sol.twoSumWithHashMap([3,2,3],6)
	# res = sol.maxSubArray([-2,1,-3,4,-1,2,1,-5,4])
	#*** res=sol.removeElement([3,2,2,4,5,3],3)
	# res=sol.containsDuplicate([0,1,2,6,3,2])
	#res=sol.minWindowSubstring(s = "AADOBECODEBANC", t = "ABC")
	#res=sol.isPalindrome(0)
	# lst1_head = sol.list_to_linkedlist([2,4,6])
	# lst2_head = sol.list_to_linkedlist([5,6,4,9])
	# res=sol.addTwoNumbers(lst1_head, lst2_head)
	# sol.print_linked_list(res)

	# res=sol.addTwoNumbers(lst1_head, lst2_head)
	# print(res)
	board=board = [[".",".","4",".",".",".","6","3","."],[".",".",".",".",".",".",".",".","."],["5",".",".",".",".",".",".","9","."],[".",".",".","5","6",".",".",".","."],["4",".","3",".",".",".",".",".","1"],[".",".",".","7",".",".",".",".","."],[".",".",".","5",".",".",".",".","."],[".",".",".",".",".",".",".",".","."],[".",".",".",".",".",".",".",".","."]]
	#F
	# [["7",".",".",".","4",".",".",".","."],[".",".",".","8","6","5",".",".","."],[".","1",".","2",".",".",".",".","."],[".",".",".",".",".","9",".",".","."],[".",".",".",".","5",".","5",".","."],[".",".",".",".",".",".",".",".","."],[".",".",".",".",".",".","2",".","."],[".",".",".",".",".",".",".",".","."],[".",".",".",".",".",".",".",".","."]]
	# T 
	# ["5","3",".",".","7",".",".",".","."],["6",".",".","1","9","5",".",".","."],[".","9","8",".",".",".",".","6","."],["8",".",".",".","6",".",".",".","3"],["4",".",".","8",".","3",".",".","1"],["7",".",".",".","2",".",".",".","6"],[".","6",".",".",".",".","2","8","."],[".",".",".","4","1","9",".",".","5"],[".",".",".",".","8",".",".","7","9"]]
	# F
	# [["8","3",".",".","7",".",".",".","."],["6",".",".","1","9","5",".",".","."],[".","9","8",".",".",".",".","6","."],["8",".",".",".","6",".",".",".","3"],["4",".",".","8",".","3",".",".","1"],["7",".",".",".","2",".",".",".","6"],[".","6",".",".",".",".","2","8","."],[".",".",".","4","1","9",".",".","5"],[".",".",".",".","8",".",".","7","9"]]
	# F 
	# [[".",".","4",".",".",".","6","3","."],[".",".",".",".",".",".",".",".","."],["5",".",".",".",".",".",".","9","."],[".",".",".","5","6",".",".",".","."],["4",".","3",".",".",".",".",".","1"],[".",".",".","7",".",".",".",".","."],[".",".",".","5",".",".",".",".","."],[".",".",".",".",".",".",".",".","."],[".",".",".",".",".",".",".",".","."]]
	sol.print_matrix(board)
	res=sol.isValidSudoku(board)
	print(res)
class Solution:
	def isValidSudoku(self, board:List[List[str]]) -> bool:
		tinygrid_hash={}
		for row in range(0,9):
			row_hash={}
			col_hash={}
			for col in range(0,9):
				row_val=board[row][col]
				col_val=board[col][row]
				row_hash[row_val] = row_hash.get(row_val,0) + 1
				col_hash[col_val] = col_hash.get(col_val,0) + 1
				if(col%3==2 and row%3==0):
					tinygrid_hash={}
					for i in range(row,row+3):
						for j in range(col-2, col+1):
							tinygrid_val=board[i][j]
							tinygrid_hash[tinygrid_val] = tinygrid_hash.get(tinygrid_val,0) + 1
							if tinygrid_val != '.' and tinygrid_hash[tinygrid_val] >1 :
								print("Dup in tinygrid at:", i,j, " dup val is ", tinygrid_val)
								return False
				if(col_val != '.' and col_hash[col_val]  >1):
					print("Dup in col at:", row,col, " dup val is ", col_val)
					return False
				if(row_val != '.' and row_hash[row_val]  >1):
					print("Dup in row at:", row,col, " dup val is ", row_val)
					return False
			print(row_hash)
		return True
	def print_matrix(self, board: List[List[str]]) -> None:
		gridstr = ""
		for row in range (len(board)):
			gridstr += "\n"
			for col in range(len(board[row])):
				gridstr += board[row][col] + " | "
				if(col%3==2):
					gridstr += "\t"
			if(row%3==2):
				gridstr += "\n"
				
		print( gridstr)
	def addTwoNumbers(self, lst1: ListNode, lst2: ListNode) -> ListNode:
		sum_head_node=curr_node=ListNode(0) # Create a dummy head for the sum result list
		sum_val=0
		carry =0
		while lst1 or lst2 or carry > 0: # Loop until both lists are exhausted and no carry is left
			sum_val = (lst1.val if lst1 else 0) + (lst2.val if lst2 else 0) + carry # Calculate sum of current digits and carry
			# print("dbg1 sum_val=",sum_val)
			carry = sum_val // 10 # 1  if sum_val > 9 else 0 # Calculate new carry
			sum_val = sum_val % 10 #0 if sum_val > 9 else sum_val  # Get the last digit of the sum
			curr_node.next=ListNode(sum_val) # Create a new node with the sum value
			curr_node=curr_node.next # Move to the new node
			# print("dbg", (lst1.val if lst1 else -1), (lst2.val if lst2 else -1),
		 	# 	"currnode=", curr_node.val, ", modified sum_val=",
			# 	sum_val, ", carry=", carry, "\n")
			lst1=lst1.next if lst1 else None # Move to the next node in lst1
			lst2=lst2.next if lst2 else None # Move to the next node in lst2
		return sum_head_node.next
	def print_linked_list(self,node:ListNode) -> None:
		while node: # Traverse the linked list
			print("printing: ", node.val)
			node = node.next  # Move to the next node
	def list_to_linkedlist(self, arr:List[int]) -> ListNode:
		head=curr= ListNode(0) # Create a dummy head node
		for num in arr: # Iterate through the input list
			curr.next=ListNode(num) # Create a new node for each element
			curr=curr.next # Move to the new node
			# print("dbg added: ", curr.val)
		# print("dbg returning head node: ", head.next.val)
		return head.next # Return the actual head of the linked list
	def containsDuplicate(self, nums: List[int]) -> bool:
		# Initialize an empty set to keep track of seen numbers
		seen = set()
		# Iterate through each number in the input list
		for num in nums:
			# Check if the current number is already in the set
			if num in seen:
				# If it is, return True because we found a duplicate
				return True
			# If it's not, add the current number to the set
			seen.add(num)
		# If no duplicates are found, return False
		return False
	def containsDuplicateB(self, nums:List[int]) -> bool:
		#containsDuplicate with array sort
		print(nums)
		nums.sort()
		print(nums)
		for i in range(1,len(nums)):
			if nums[i]==nums[i-1]:
				return True
		return False
	def containsDuplicateC(nums: List[int]) -> bool:
		#containsDuplicateWithBitArray
		# Assuming the range of numbers is 0 to 10^6
		bit_array = [0] * (10**6 // 32 + 1)  # Each int can store 32 bits
		for num in nums:
			bit_index = num // 32
			bit_position = num % 32
			if bit_array[bit_index] & (1 << bit_position):
				return True
			bit_array[bit_index] |= (1 << bit_position)

		return False
	def maxSubArray(self, nums:List) -> int:
		# Initialize runningSum and maxSum with the first element of the array
		# runningSum helps us decide whether to continue adding elements to the current subarray
		# or start a new subarray from the current element. maxSum stores the maximum subarray sum found so far
		runningSum=maxSum=nums[0]
		# Iterate through the array starting from the second element
		for i in range(1, len(nums)):
			 # Update runningSum to be the maximum of (runningSum + current element) or (current element)
			# discard the running sum if it is lower than the current element by itself (may have negative numbers)
			# If the running sum (the sum of the current subarray) becomes negative or less than the current element,
			# it means that including the previous elements is not beneficial. In such cases, starting a new
			# subarray from the current element is more advantageous.
			runningSum = max(runningSum+nums[i], nums[i])#max because will discard running sum if its lower than just current element by itself
			# Update maxSum to be the maximum of (runningSum) or (maxSum)
			maxSum=max(runningSum, maxSum)
			print(i, " ", nums[i], " " , runningSum, " ", maxSum)
		return maxSum
	def isPalindrome(self, x: int) -> bool:
		# Store the original number in a temporary variable (we can't change x)
		tmp=x
		# Initialize a variable to store the reversed number
		reversed_num=0
		# Loop until the temporary number becomes 0
		while(tmp > 0):
			# Extract the lowest digit of the temporary number
			lowest_digit=tmp%10 # For example, 123 % 10 = 3
			# Remove the lowest digit from the temporary number
			tmp=int((tmp-lowest_digit)/10) # For example, (123 - 3) / 10 = 12
			# Alternatively, we could use: tmp = int(tmp / 10)
			#tmp=int(tmp/10)#new number without lowest digit: 123->12
			 # Update the reversed number by shifting its digits to the left and adding the lowest digi
			reversed_num=reversed_num*10+lowest_digit # For example, 0 * 10 + 3 = 3
			print("x=", x, " lowest_digit=", lowest_digit, " tmp=", tmp, " reversed_num=", reversed_num)
		# Check if the reversed number is equal to the original number (is a palindrome)
		return reversed_num==x
	def intToRoman(self, num:int) -> str:
		#Define a tuple with Roman numerals and their corresponding integer values
		# Note in this case, the special cases are directly in the data, this simplifies the code
		# because there is no longer to handle special cases directly in code logic, it's auto mapped within the data!
		i_to_r_map_array = [(1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'),
			(100, 'C'), (90, 'XC'), (50, 'L'), (40, 'XL'),
			(10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I') ]
		roman_str=""
		# Loop through each value and symbol pair
		for val,symbol in i_to_r_map_array:
			# While the number is greater than or equal to the current highest value we're iterating on
			while(num>=val):
				print(num,val,symbol, roman_str)
				num -= val
				roman_str += symbol
		return roman_str
	def intToRomanA(self, num: int) -> str:
		# Mapping of integers to their respective Roman numeral representations
		i_to_r_map = {1000:'M', 500:'D', 100:'C', 50:'L', 10:'X', 5:'V', 1:'I' }
		# Initialize an empty string for the resulting Roman numeral.
		roman_str=""
		# Convert the mapping dictionary into a list of tuples for iteration
		i_to_r_map_array = list(i_to_r_map.items())
		res=0
		# deferred_subtraction_index tracks keeps track of the index in the i_to_r_map_array
		#  where a subtraction operation is pending, used for special cases 900, 40, 90.
		# If a subtraction is pending (i.e., deferred_subtraction_index is not -1),
		#  the code constructs the Roman numeral by combining the current numeral with the numeral
		#  at the deferred_subtraction_index.
		deferred_subtraction_index=-1
		print("num=%d" %(num) )
		# Iterate over each tuple in the list of mappings.
		for i  in range(len(i_to_r_map_array)):
			val,symbol = i_to_r_map_array[i]
			rem=num%val
			res=int(num/val) # Calculate how many times 'val' fits into 'num'
			if(res>0): # If 'res' is greater than zero, we need to add Roman numerals to our string
				sub=""
				#handle special case 4,9 or 40,90,900 (deferred_subtraction_index)
				if(num==4 or num==9 or deferred_subtraction_index>-1):
					if(deferred_subtraction_index>-1):
						sub =  i_to_r_map_array[i][1] + i_to_r_map_array[deferred_subtraction_index-1][1]
						deferred_subtraction_index=-1
						num -= res*val
					else:
						sub += "I" + i_to_r_map_array[i-1][1] #safe to subtract 1 because keys 5,10 are not at index0 in i_to_r_map_array
						num -= num
				# Handle max three rule for 1000,100,10,1 symbols
				elif val in [1000,100,10,1]:
					if(res>3):
						sub=symbol+ i_to_r_map_array[i-1][1]
					else:
						sub += (symbol*res)
					num-= (res*val)
				#Handle max 1 rule for 500,50,5 symbols
				elif val in [500,50,5]:
					# andles the case where the current numeral symbol should be added exactly once
					#  to the result string, and the remaining value (rem) is small enough to be handled
					#  by the next smaller numeral without violating the Roman numeral rules (e.g., not having
					#  four consecutive identical symbols).
					if(res==1 and rem/i_to_r_map_array[i+1][0]<4):
						sub += symbol # Add current symbol if it fits exactly once and the remainder is manageable
						num=rem # Update num to the remainder to process the next smaller numeral
					else:
						deferred_subtraction_index=i
				roman_str +=sub
		print("      roman= %s" %(roman_str) )
		return roman_str
	def fib(self, n: int) -> int:
		 # Base cases: return n if n is 0 or 1
		if( n in [0,1]):return n
		# Initialize the first two Fibonacci numbers
		first, second = 0, 1
		# Counter to keep track of the number of iterations
		ctr=0
		# Loop until the counter reaches n
		while ctr <n :
			# Temporarily store the value of second
			tmp=second
			# Update second to be the sum of first and second (next Fibonacci number)
			second = first+second
			# Update first to be the old value of second
			first=tmp
			print(n, first, second)
			# Increment the counter
			ctr +=1
        # Return the nth Fibonacci number
		return first
	def isValidParentheses(self, s:str)-> bool:
		# Dictionary to hold matching pairs of parentheses
		#note key is opening parenthesis, value is matching closing parenthesis
		parenthesis_pairs = { "{":"}", "(":")", "[":"]"}

		#use a deque object (double edged queue) to keep track of open parentheses
		open_pairs=deque()
		for c in s:
			# If the character is an opening parenthesis
			if( parenthesis_pairs.get(c,-1) != -1):
				open_pairs.append(c) # Add it to the deque
			else: # If the character is a closing parenthesis
				if len(open_pairs)==0:# if no opening parenthesis are present
					return False
				last = open_pairs.pop() # Pop the last opening parenthesis
				# Check if the closing parenthesis corresponds to the last opening parenthesis popped from queue
				if(c != parenthesis_pairs.get(last,-1) ):
					return False
		# If there are no unmatched opening parentheses left, return True
		return len(open_pairs)==0
	def twoSum(self, nums: List[int], target: int) -> List[int]:
		# Dictionary to store the indices of numbers such that
		# the key is the complement (target - number)
		# and the value is the index of the number in the list
		complement_num_index_map={}
		# Initialize the return list with default values
		ret=[-1,-1]
		# Iterate through the list of numbers
		for i in range(len(nums)):
			# Check if the current number is a complement of any previously seen number
        	# If it is, it means we have found the two numbers that add up to the target
			# Recall, the map value includes the index of the previously seen number
			if complement_num_index_map.get(nums[i],-1) > -1:
				# If found, set the indices in the return list
				ret[0]=complement_num_index_map[nums[i]]
				ret[1]=i
			# Store the index of the current number's complement (i.e., target - current number)
			# This helps us quickly check if the complement exists in the subsequent iterations
			# For example, if i=0, target=9, nums[i]=2, then complement_num_index_map[7 (i.e., 9-2)] = 0
			complement_num_index_map[ target - nums[i] ]=i
		# Return the indices of the two numbers that add up to the target
		return ret
	def twoSum_bruteforce(self, nums: List[int], target: int) -> List[int]:
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

def main_old():
	print('old main')
	# Linked List solution:
	# sol=Solution()
	# lst1 = list_to_linkedlist([2, 4, 3])
	# lst2 = list_to_linkedlist([5, 6, 4])
	# res=sol.addTwoNumbers(lst1,lst2)
	# print_linked_list(res)
	# end Linked List solution

if __name__ == '__main__':
	main()