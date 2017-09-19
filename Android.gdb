
#-------------------------------------------------------------
#                        Android libc++
#-------------------------------------------------------------
#
# std::list<T>
#

define pList
	if $argc == 0
		help pList
	else
		set $head = &$arg0
		set $current = $arg0.__end_.__next_
                #p /x $head
                #p /x $current
		set $size = 0
                set $pointer_size = sizeof(unsigned long)

		# dump memory of std::list<T>
                printf "\n- dump memory of std::list<T>(%d bytes):\n", $pointer_size * 3
                if $pointer_size == 4
			x /3xw $head
                else
			x /6xw $head
                end

		# traverse std::list<T>
		if $argc >= 2
			printf "\n- dump elements of std::list<T>:\n"
		end
		while $current != $head
                        set $data = (unsigned long)$current + $pointer_size * 2
                        #p /x $data
			if $argc == 2
				printf "elem[%-3u]: ", $size
				p *($arg1*)($data)
			end
			if $argc == 3
				if $size == $arg2
					printf "elem[%u]: ", $size
					p *($arg1*)($data)
				end
			end
                        set $current = *(unsigned long *)((unsigned long)$current + $pointer_size)
			set $size++
		end

		printf "\n- Misc:\n"
		printf "std::list<T> size = %u \n", $size
		if $argc == 1
			printf "pList "
			whatis $arg0
			printf "Use pList <variable_name> <element_type> to see the elements in the list.\n"
		end
	end
end

document pList
	Prints Android std::list<T> information.
	Syntax: pList <list> <T> <idx>: Prints list size, if T defined all elements or just element at idx
	Examples:
	pList 'art::Runtime::instance_'->thread_list_->list_                     - prints list size and definition
	pList 'art::Runtime::instance_'->thread_list_->list_  'art::Thread'*     - prints all elements and list size
	pList 'art::Runtime::instance_'->thread_list_->list_  'art::Thread'* 0   - prints the first element in the list (if exists) and list size
end

#-------------------------------------------------------------
#                        Android ART
#-------------------------------------------------------------

#
# Print thread list inforamtiion, such as tid, name and so on.
#
define pThreadList
	set $head = &'art::Runtime::instance_'->thread_list_->list_
	#p /x $head

	set $current = 'art::Runtime::instance_'->thread_list_->list_.__end_.__next_
	#p /x $current

	set $pointer_size = sizeof(unsigned long)
	while $current != $head
		set $t = ('art::Thread' *)(*(unsigned long *)((unsigned long)$current + $pointer_size * 2))
		#p /x $t
		set $name = *(unsigned long *)((unsigned long)$t->tlsPtr_.name + $pointer_size * 2)
		printf "Thread[tid = %-5d, name = %-40s]: flag = %d, state = %d\n", $t->tls32_.tid, $name, $t->tls32_.state_and_flags.as_struct.flags, $t->tls32_.state_and_flags.as_struct.state

		set $current = *(unsigned long *)((unsigned long)$current + $pointer_size)
	end
end

#
# boot_image_spaces_ is a std::vector data structure
#
define pBootImageSpaces
	set $boot_image_spaces = &'art::Runtime::instance_'->heap_->boot_image_spaces_
	set $begin = *(unsigned long *)$boot_image_spaces
	set $end = *(unsigned long *)((unsigned long)$boot_image_spaces + $pointer_size)

	# dump memory of std::vector<T>
	set $pointer_size = sizeof(void *)
	if $pointer_size == 4
		printf "&boot_image_spaces_ = 0x%08x\n", $boot_image_spaces
		printf "begin = 0x%08x\n", $begin
		printf "end = 0x%08x\n", $end
	else
		printf "&boot_image_spaces_ = 0x%016x\n", $boot_image_spaces
		printf "begin = 0x%016x\n", $begin
		printf "end = 0x%016x\n", $end
	end

	# traverse the std::vector<T>
	while $begin < $end
		set $space = *(unsigned long *)$begin
		#p /x *('art::gc::space::ImageSpace' *)$space
		set $begin = (unsigned long)$begin + $pointer_size
	end
end

define pRegionSpace
	#set $num_regions_ = 'art::Runtime::instance_'->heap_->concurrent_copying_collector_->region_space_->num_regions_
	set $num_regions_ = 256
	set $regions_ = *(unsigned long *)&'art::Runtime::instance_'->heap_->concurrent_copying_collector_->region_space_->regions_
	set $i = 0

	while $i < $num_regions_
		set $region = $regions_ + $i * sizeof(art::gc::space::RegionSpace::Region)
		p *(art::gc::space::RegionSpace::Region *)$region
		set $i++
	end
end
