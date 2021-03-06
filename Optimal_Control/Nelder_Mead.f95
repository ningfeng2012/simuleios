!!------------Nelder_Mead.f95-------------------------------------------------!!
!
!             Nelder Mead -- Downhill simplex in fortran!
!
! Purpose: To implement a simple optimization scheme in Fortran!
!
!   Notes: the value array has 3 accessory elements for different things:
!              1. Centroid position
!
!!----------------------------------------------------------------------------!!

program neldermead

!!----------------------------------------------------------------------------!!
!  DEFINITIONS
!!----------------------------------------------------------------------------!!

      call downhill

      write(*,*)

      write(*,*) "yoyoyo, sales claus gave you some yoyos!"

end program

!!----------------------------------------------------------------------------!!
! SUBROUTINES
!!----------------------------------------------------------------------------!!

!! The actual method
!! The nelder mead method 
subroutine downhill
      implicit none
      integer, parameter             :: dim = 8
      integer :: min, max, i, minsave, maxsave
      integer, dimension(dim, dim-1) :: list
      real*8, dimension(dim, dim-1)  :: weights
      real*8, dimension(2, dim)      :: pos
      real*8, dimension(dim - 1)     :: value
      real*8  :: alpha = 1, beta = 0.5, gamma = 1.5, dist, cutoff = 0.0001
      real*8  :: xsave, ysave, minval, check

      interface
          subroutine findval(pos, value, dim)
              real*8, dimension(:,:) :: pos
              real*8, dimension(:)   :: value
              integer                :: dim
          end subroutine findval
      end interface

      interface
          subroutine findval_sales(pos, list, value, dim)
              real*8, dimension(:,:) :: pos
              integer, dimension(:,:):: list
              real*8, dimension(:)   :: value
              integer                :: dim
          end subroutine findval_sales
      end interface

      interface
          subroutine populate(pos, dim)
              real*8, dimension(:,:) :: pos
              integer                :: dim
          end subroutine populate
      end interface

      interface
          subroutine pop_list(list, dim, pos, weights)
              integer, dimension(:,:) :: list
              real*8, dimension(:,:)  :: pos, weights
              integer                 :: dim
          end subroutine pop_list
      end interface

      interface
          subroutine minmax(value, min, max)
              real*8, intent(in)   :: value(:)
              integer, intent(out) :: min, max
          end subroutine minmax
      end interface

      interface
          subroutine centroid(pos, min, dim)
              real*8, intent(inout)  :: pos(:,:)
              integer, intent(in)    :: min, dim
          end subroutine centroid
      end interface

      interface
          subroutine centroid_sales(weights, min, dim)
              real*8, intent(inout)  :: weights(:,:)
              integer, intent(in)    :: min, dim
          end subroutine centroid_sales
      end interface

      interface
          subroutine reflect(pos, min, dim, alpha)
              real*8, intent(inout)  :: pos(:,:)
              integer, intent(in)    :: min, dim
              real*8, intent(in)     :: alpha
          end subroutine reflect
      end interface

      interface
          subroutine reflect_sales(weights, min, dim, alpha)
              real*8, intent(inout)  :: weights(:,:)
              integer, intent(in)    :: min, dim
              real*8, intent(in)     :: alpha
          end subroutine reflect_sales
      end interface

      interface
          subroutine contract(pos, min, dim, beta)
              real*8, intent(inout)  :: pos(:,:)
              real*8, intent(in)     :: beta
              integer, intent(in)    :: dim, min
          end subroutine contract
      end interface

      interface
          subroutine contract_sales(weights, min, dim, beta)
              real*8, intent(inout)  :: weights(:,:)
              real*8, intent(in)     :: beta
              integer, intent(in)    :: dim, min
          end subroutine contract_sales
      end interface

      interface
          subroutine expand(pos, min, dim, gamma)
              real*8, intent(inout)  :: pos(:,:)
              integer, intent(in)    :: min, dim
              real*8, intent(in)     :: gamma
          end subroutine expand
      end interface

      interface
          subroutine expand_sales(weights, min, dim, gamma)
              real*8, intent(inout)  :: weights(:,:)
              integer, intent(in)    :: min, dim
              real*8, intent(in)     :: gamma
          end subroutine expand_sales
      end interface

      interface
          subroutine contractall(pos, min, dim)
              real*8, intent(inout)  :: pos(:,:)
              integer, intent(in)    :: min, dim
          end subroutine contractall
      end interface

      interface
          subroutine contractall_sales(weights, min, dim)
              real*8, intent(inout)  :: weights(:,:)
              integer, intent(in)    :: min, dim
          end subroutine contractall_sales
      end interface


      !open(100, file = "simplex_points.dat")
      !open(200, file = "centroids.dat")

      !! initialize everything
      call populate(pos, dim)
      call findval(pos, value, dim)
      call minmax(value, min, max)
      call centroid(pos, min, dim)

      !write(*,*) pos(1,1), pos(1,2), pos(1,3), pos(1,4)
      !write(*,*) pos(2,1), pos(2,2), pos(2,3), pos(2,4)
      !write(*,*) min, max, dim

      i = 0

      dist = sqrt((pos(1,min)-pos(1,max)) * (pos(1,min)-pos(1,max)) &
                  + (pos(2,min)-pos(2,max)) * (pos(2,min)-pos(2,max)))

      !write(*,*) dist

      !! Nelder-Mead optimal control
      do while (dist > cutoff)
      !do while (i < 10)
          !! Reflection first
          write(*,*) i
          minsave = min
          minval = value(min)
          xsave = pos(1, min)
          ysave = pos(2, min)
          call reflect(pos, min, dim, alpha)
          call findval(pos, value, dim)
          call minmax(value, min, max)
          call centroid(pos, min, dim)

          !! Expansion if the minimum value becomes the maximum
          if (minsave.EQ.max) then
              !write(*,*) "expanding...", dist
             
              maxsave = max
              xsave = pos(1, max)
              ysave = pos(2, max)
              call expand(pos, max, dim, gamma)
              call findval(pos, value, dim)
              call minmax(value, min, max)

              !! Setting things back, if expansion is worse than 
              !! standard reflection
              if (maxsave.NE.max) then
                  pos(1, maxsave) = xsave
                  pos(2, maxsave) = ysave
                  call findval(pos, value, dim)
                  call minmax(value, min, max)
              end if

              call centroid(pos, min, dim)


          !! Contract from old position if minima value is still minima value
          else if (minsave.NE.max) then
              !write(*,*) "it's okay, checking to keep", dist

              !! if minima is still minima, contract everything towards max
              if (minsave.EQ.min) then
                  !write(*,*) "it's still bad, checking to keep", dist
                  !write(*,*) pos(1,1), pos(1,2), pos(1,3), pos(1,4)
                  !write(*,*) pos(2,:)
                  !write(*,*) pos

                  check = value(min)

                  if (check < minval) then
                      !write(*,*) "It's awful! flipping back!", dist
                      pos(1, min) = xsave
                      pos(2, min) = ysave
                      value(min) = minval
                  end if

                  minval = value(min)

                  !write(*,*) "contracting...", dist

                  call contract(pos, min, dim, beta)
                  call findval(pos, value, dim)
                  call minmax(value, min, max)
                  call centroid(pos, min, dim)

                  check = value(min)

                  if (check < minval) then
                      !write(*,*) "contract all...", dist
                      call contractall(pos, max, dim)
                      call findval(pos, value, dim)
                      call minmax(value, min, max)
                      call centroid(pos, min, dim)
                  end if

              end if

          end if
          i = i + 1
          dist = sqrt((pos(1,min)-pos(1,max)) * (pos(1,min)-pos(1,max)) &
                      + (pos(2,min)-pos(2,max)) * (pos(2,min)-pos(2,max)))

          !write(100,*) pos(1,1), pos(2,1)
          !write(100,*) pos(1,2), pos(2,2)
          !write(100,*) pos(1,3), pos(2,3)
          !write(100,*) pos(1,1), pos(2,1)
          !write(100,*)
          !write(100,*)

      end do

      write(*,*) pos(1,:)
      write(*,*) pos(2,:)
      write(*,*) min, max, dim

      !!call pop_list(list, dim, pos, weights)
      !!do i = 1, dim
      !!    write(*,*) list(i,:)
      !!    write(*,*) pos(1, i), pos(2,i)
      !!    write(*,*) weights(i,:)
      !!end do

      !!call findval_sales(pos, list, value, dim)

      write(*,*) value


end subroutine

!! Total contraction
pure subroutine contractall(pos, max, dim)
      implicit none
      real*8, dimension(:,:), intent(inout) :: pos
      integer, intent(in)                   :: max, dim
      integer                               :: i

      do i = 1, dim - 1
          if (i.NE.max) then
              pos(1,i) = (pos(1, i) + pos(1, max)) * 0.5
              pos(2,i) = (pos(2, i) + pos(2, max)) * 0.5
          end if
      end do

end subroutine

!! Total contraction for salesman
pure subroutine contractall_sales(weights, max, dim)
      implicit none
      real*8, dimension(:,:), intent(inout) :: weights
      integer, intent(in)                   :: max, dim
      integer                               :: i, j

      do i = 1, dim - 1
          if (i.NE.max) then
              do j = 1, dim - 1
                  weights(i,j) = (weights(i,j) + weights(dim,j)) * 0.5
              end do
          end if
      end do

end subroutine

!! for Nelder Mead reflections
pure subroutine reflect(pos, min, dim, alpha)
      implicit none
      real*8, dimension(:,:), intent(inout) :: pos
      integer, intent(in)                   :: min, dim
      real*8, intent(in)                    :: alpha

      pos(1,min) = (1 + alpha) * pos(1,dim) - alpha * pos(1, min)
      pos(2,min) = (1 + alpha) * pos(2,dim) - alpha * pos(2, min)

end subroutine

!! for Nelder Mead reflections for salesman
pure subroutine reflect_sales(weights, min, dim, alpha)
      implicit none
      real*8, dimension(:,:), intent(inout) :: weights
      integer, intent(in)                   :: min, dim
      real*8, intent(in)                    :: alpha
      integer                               :: i

      do i = 1, dim - 1
          weights(min,i) = (1 + alpha)*weights(dim,i) - alpha*weights(min, i)
      end do

end subroutine


!! for Nelder Mead contractions
pure subroutine contract(pos, min, dim, beta)
      implicit none
      real*8, dimension(:,:), intent(inout) :: pos
      integer, intent(in)                   :: min, dim
      real*8, intent(in)                    :: beta
      integer                               :: i

      pos(1,min) = (1 - beta) * pos(1,dim) + beta * pos(1, min)
      pos(2,min) = (1 - beta) * pos(2,dim) + beta * pos(2, min)

end subroutine

!! for Nelder Mead contractions for salesman
pure subroutine contract_sales(weights, min, dim, beta)
      implicit none
      real*8, dimension(:,:), intent(inout) :: weights
      integer, intent(in)                   :: min, dim
      real*8, intent(in)                    :: beta
      integer                               :: i

      do i = 1, dim - 1
          weights(min,i) = (1 - beta)*weights(dim,i) + beta*weights(min, i)
      end do

end subroutine

!! for Nelder Mead expansions
pure subroutine expand(pos, min, dim, gamma)
      implicit none
      real*8, dimension(:,:), intent(inout) :: pos
      integer, intent(in)                   :: min, dim
      real*8, intent(in)                    :: gamma

      pos(1,min) = (1 - gamma) * pos(1,dim) + gamma * pos(1, min)
      pos(2,min) = (1 - gamma) * pos(2,dim) + gamma * pos(2, min)

end subroutine

!! for Nelder Mead expansions for salesman
pure subroutine expand_sales(weights, min, dim, gamma)
      implicit none
      real*8, dimension(:,:), intent(inout) :: weights
      integer, intent(in)                   :: min, dim
      real*8, intent(in)                    :: gamma
      integer                               :: i

      do i = 1, dim - 1
          weights(min,i) = (1 - gamma)*weights(dim,i) + gamma*weights(min, i)
      end do

end subroutine

!! Finds the minima and maxima
!! We need a better way to search through the initial elements in our array!
subroutine minmax(value, min, max)
      implicit none
      real*8, intent(in)   :: value(:)
      integer, intent(out) :: min, max
      integer              :: max_array(1), min_array(1)

      min_array = minloc(value)
      max_array = maxloc(value)

      min = min_array(1)
      max = max_array(1)
end subroutine

!! populates grid
subroutine populate(pos, dim)
      implicit none
      integer                :: dim
      real*8, dimension(:,:) :: pos
      integer                :: i

      !!call init_random_seed()

      do i = 1,dim -1
          call random_number(pos(1,i))
          pos(1,i) = (pos(1,i) - 0.5)
          call random_number(pos(2,i))
          pos(2,i) = (pos(2,i) - 0.5)
      end do
      
end subroutine

!! finds centroid position 
subroutine centroid(pos, min, dim)
      implicit none
      real*8, intent(inout)  :: pos(:,:)
      integer, intent(in)    :: min, dim
      integer                :: i
      real*8                 :: xsum, ysum

      pos(1, dim) = 0
      pos(2, dim) = 0
      xsum = 0
      ysum = 0

      do i = 1,dim - 1
          if (i.NE.min) then
              xsum = xsum + pos(1, i)
              ysum = ysum + pos(2, i)
          end if
      end do

      pos(1, dim) = xsum / real(dim - 2)
      pos(2, dim) = ysum / real(dim - 2)
      
end subroutine

!! finds centroid position for salesman
subroutine centroid_sales(weights, min, dim)
      implicit none
      real*8, intent(inout)  :: weights(:,:)
      integer, intent(in)    :: min, dim
      integer                :: i, j


      do i = 1,dim - 1
          if (i.NE.min) then
              do j = 1, dim - 1
                  weights(dim, j) = weights(dim, j) + weights(i, j)
              end do
          end if
      end do

      do i = 1, dim - 1
          weights(dim, j) = weights(dim, j) / (dim - 1)
      end do

end subroutine


!! minimum currently set to 0.5, should be found via Downhill Simplex!
subroutine findval(pos, value, dim)
      implicit none
      real*8,  dimension(:,:):: pos
      real*8,  dimension(:)  :: value
      real*8                 :: sourcex = 0.5, sourcey = 1.0
      integer                :: dim
      integer                :: i

      do i = 1, dim - 1
          value(i) = -sqrt((pos(1,i) - sourcex) * (pos(1,i) - sourcex) &
                     + (pos(2,i) - sourcey) * (pos(2,i) - sourcey))
      end do

end subroutine

!! Finds the initial list variable set
subroutine pop_list(list, dim, pos, weights)
      implicit none
      integer, dimension(:,:) :: list
      integer                 :: dim, i, j, k, swap, tmp
      integer, parameter      :: seed = 1
      real*8                  :: var, theta, roll = 0
      real*8, dimension(:,:)  :: pos, weights

      !! Initialization!
      do i = 1, dim - 1
          do j = 1,dim - 1
              list(i,j) = j
          end do 
          !! This guy swaps everything around to get random init lists.
          do k = dim-1, 1, -1
              call random_number(var)
              swap = mod(ceiling(var*dim-1), k) + 1
              write(*,*) swap, k
              tmp = list(i, k) 
              list(i,k) = list(i,swap)
              list(i,swap) = tmp
          end do
      end do

      !! initialize each new position
      do i = 1, dim - 1
          theta = i * 2 * 3.14159 / dim
          pos(1,i) = cos(theta)
          pos(2,i) = sqrt(1 - (pos(1,i) * pos(1,i)))
      end do

      !! initialize the weighting scheme for NM transformations
      do i = 1, dim - 1
          roll = 0
          do j = 1, dim - 1
              weights(i, list(i,j)) = roll
              roll = roll + 0.5
          end do
      end do

end subroutine

!! finding new values for new possible routes with Santa Claus
subroutine findval_sales(pos, list, value, dim)
      implicit none
      integer, dimension(:,:) :: list
      real*8, dimension(:,:)  :: pos
      real*8, dimension(:)    :: value
      real*8                  :: dist, delx, dely
      integer                 :: dim, i, j

      do i = 1,dim-1
          do j = 1,dim-2
              delx = (pos(1,list(i,j)) - pos(1,list(i,j+1))) & 
                     * (pos(1,list(i,j)) - pos(1,list(i,j+1)))
              dely = (pos(2,list(i,j)) - pos(2,list(i,j+1))) & 
                     * (pos(2,list(i,j)) - pos(2,list(i,j+1)))
              dist = sqrt((delx * delx) + (dely * dely))

              value(i) = value(i) + dist
          end do
      end do
      
end subroutine
