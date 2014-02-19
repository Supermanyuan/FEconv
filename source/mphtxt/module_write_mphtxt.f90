module module_write_mphtxt
!-----------------------------------------------------------------------
! Module for mphtxt file read
! Last update: 07/02/2014
!-----------------------------------------------------------------------
use module_COMPILER_DEPENDANT, only: real64
use module_os_dependant, only: maxpath
use module_report, only:error
use module_convers
use module_ALLOC
use module_mesh
use module_pmh
contains

!***********************************************************************
! OUTPUT PROCEDURES
!***********************************************************************
!-----------------------------------------------------------------------
! write: write mphtxt file header
!-----------------------------------------------------------------------

subroutine write_mphtxt_header(iu, pmh)
  integer, intent(in)        :: iu  ! File unit number
  type(pmh_mesh), intent(in) :: pmh ! PMH mesh


  call write_comment(iu,                           '#','Converted with FEconv')
  call write_empty_line(iu)
  call write_comment(iu,                           '#','Major & minor version')
  call write_line(iu, '0 1')
  call write_line(iu, trim(string(size(pmh%pc,1))),'#','number of tags')
  call write_comment(iu,                           '#','Tags')
  do i=1, size(pmh%pc,1)
    call write_string(iu, 'mesh'//trim(string(i)))
  enddo
  ! Types of objects in mphtxt mesh
  call write_line(iu, trim(string(size(pmh%pc,1))),'#','number of types')
  call write_comment(iu,                           '#','Types')
  do i=1, size(pmh%pc,1)
    call write_string(iu, 'obj')
  enddo
  call write_empty_line(iu)
  
end subroutine


subroutine write_mphtxt_object(iu, pmh_o, n)
  integer, intent(in)        :: iu    ! File unit number
  type(piece), intent(inout) :: pmh_o ! PMH piece
  integer, intent(in)        :: n     ! Piece number
  integer                    :: i

  call write_comment(iu,                        '#','--------- Object '//trim(string(n))//' ----------')
  call write_empty_line(iu)
  call write_line(iu, '0 0 1')
  call write_string(iu, 'Mesh',                 '#', 'class')
  call write_line(iu, '2',                      '#', 'version')
  call write_line(iu, string(pmh_o%dim),        '#', 'sdim')
  ! Node coords
  if(pmh_o%nver == 0) then                                                    ! z = nodes
    call write_line(iu, string(pmh_o%nnod),     '#', 'number of mesh points') ! nnod
    call write_line(iu, '1',                    '#', 'lowest mesh point index')
    call write_empty_line(iu)
    call write_comment(iu,                      '#', 'Mesh point coordinates')
    do i=1,pmh_o%nnod
      call write_line(iu, string(pmh_o%z(:,i)))
    enddo
  else                                                                        ! z = vertices
    call write_line(iu, string(pmh_o%nver),     '#', 'number of mesh points') ! nver
    call write_line(iu, '1',                    '#', 'lowest mesh point index')
    call write_empty_line(iu)
    call write_comment(iu,                      '#', 'Mesh point coordinates')
    do i=1,pmh_o%nver
      call write_line(iu, string(pmh_o%z(:,i)))
    enddo
  endif

  ! Element groups types
  call write_empty_line(iu)
  call write_line(iu, string(size(pmh_o%el,1)), '#', 'number of element types')
  call write_empty_line(iu)

  do i=1, size(pmh_o%el,1)
    call write_mphtxt_etype(iu, pmh_o%el(i),i)
  enddo

  
end subroutine


subroutine write_mphtxt_etype(iu, pmh_t,n)
  integer, intent(in)       :: iu    ! File unit number
  type(elgroup), intent(inout) :: pmh_t ! PMH elgroup
  integer, intent(in)       :: n     ! Piece number
  integer                   :: i

  ! Element type
  call write_comment(iu,                           '#', 'Type #'//trim(string(n)))
  call write_empty_line(iu)
  call write_string(iu,mphtxt_get_desc(pmh_t%type),'#', 'type name')
  call write_empty_line(iu)
  ! Node conectivity
  if(allocated(pmh_t%nn)) then
    call write_line(iu, string(size(pmh_t%nn,1)),  '#', 'number of nodes per element')
    call write_line(iu, string(pmh_t%nel),         '#', 'number of elements')
    call write_comment(iu,                         '#', 'Elements')

    do i=1, size(pmh_t%nn,2)
      call mphtxt_node_ordering(pmh_t%nn(:,i), pmh_t%type)
      call write_line(iu, string(pmh_t%nn(:,i)))
    enddo
    call write_empty_line(iu)
    call write_line(iu, string(size(pmh_t%nn,1)),  '#', 'number of parameter values per element')
  elseif(allocated(pmh_t%mm)) then
    call write_line(iu, string(size(pmh_t%mm,1)),  '#', 'number of nodes per element')
    call write_line(iu, string(pmh_t%nel),         '#', 'number of elements')
    call write_comment(iu,                         '#', 'Elements')
    do i=1, size(pmh_t%mm,2)
      call write_line(iu, string(pmh_t%mm(:,i)))
    enddo
    call write_empty_line(iu)
    call write_line(iu, string(size(pmh_t%nn,1)),  '#', 'number of parameter values per element')

  else
    call error('mphtxt/write_etype# Wrong node definition: No allocated')
  endif
  ! Parameters
  call write_line(iu, '0',                         '#', 'number of parameters')
  call write_comment(iu,                           '#', 'Parameters')
  call write_empty_line(iu)
  ! Geometric entity indices
  call write_line(iu, string(size(pmh_t%ref,1)),   '#', 'number of geometric entity indices')
  call write_comment(iu,                           '#', 'Geometric entity indices')
  do i=1, size(pmh_t%ref,1)
    call write_line(iu, string(pmh_t%ref(i)))
  enddo
  ! Up/down pairs
  call write_empty_line(iu)
  call write_line(iu, '0',                         '#', 'number of up/down pairs')
  call write_comment(iu,                           '#', 'Up/down')
  call write_empty_line(iu)


end subroutine


subroutine write_line(iu,line,ch,comm)
  integer, intent(in) :: iu ! File unit number
  character(len=*), intent(in) :: line ! String
  character(len=*), optional, intent(in) :: ch ! String: Comment character
  character(len=*), optional, intent(in) :: comm ! String: Comment
  character(len=MAXPATH) :: aux

  if(present(comm)) then
    if(present(ch)) then
      aux = trim(ch)//' '//trim(comm)
    else
      aux = '# '//trim(comm)
    endif
  else
    aux = ''
  endif


  write(unit=iu, fmt='(a)', iostat = ios) trim(line)//' '//trim(aux)
  if (ios /= 0) call error('write_mphtxt/header, #'//trim(string(ios)))

end subroutine

subroutine write_comment(iu,ch,line)
  integer, intent(in) :: iu ! File unit number
  character(len=*), intent(in) :: ch ! String: Comment character
  character(len=*), intent(in) :: line ! String

  call write_line(iu,trim(ch)//' '//trim(line))

end subroutine

subroutine write_empty_line(iu)
  integer, intent(in) :: iu ! File unit number

  call write_line(iu,'')

end subroutine

subroutine write_string(iu,str,ch,comm)
  integer, intent(in) :: iu ! File unit number
  character(len=*), intent(in) :: str ! String
  character(len=*), optional, intent(in) :: ch ! String: Comment character
  character(len=*), optional, intent(in) :: comm ! String: Comment
  character(len=MAXPATH) :: aux1, aux2

  if(present(ch)) then
    aux1 = trim(ch)
  else
    aux1 = ''
  endif

  if(present(comm)) then
    aux2 = trim(comm)
  else
    aux2 = ''
  endif

  call write_line(iu,trim(string(len_trim(str)))//' '//trim(str),trim(aux1),trim(aux2))

end subroutine

function mphtxt_get_desc(num) result(res)

  integer, intent(in) :: num
  character(len=MAXPATH) :: res

    res = ''


    if((FEDB(num)%nver_eq_nnod .eqv. .true.) .and. (1==FEDB(num)%lnn) .and. &     ! Node
        (1==FEDB(num)%lnv) .and. (0==FEDB(num)%lne) .and. (0==FEDB(num)%lnf)) then
      res = 'vtx'
      call info('Element type: Node')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .true.) .and. (2==FEDB(num)%lnn) .and. & ! Edge Lagrange P1
        (2==FEDB(num)%lnv) .and. (1==FEDB(num)%lne) .and. (0==FEDB(num)%lnf)) then
      res = 'edg'
      call info('Element type: Edge lagrange P1')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .true.) .and. (3==FEDB(num)%lnn) .and. & ! Triangle Lagrange P1
        (3==FEDB(num)%lnv) .and. (3==FEDB(num)%lne) .and. (0==FEDB(num)%lnf)) then
      res = 'tri'
      call info('Element type: Triangle lagrange P1')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .true.) .and. (4==FEDB(num)%lnn) .and. & ! Quadrangle Lagrange P1
        (4==FEDB(num)%lnv) .and. (4==FEDB(num)%lne) .and. (0==FEDB(num)%lnf)) then
      res = 'quad'
      call info('Element type: Quadrangle lagrange P1')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .true.) .and. (4==FEDB(num)%lnn) .and. & ! Tetrahedron Lagrange P1
        (4==FEDB(num)%lnv) .and. (6==FEDB(num)%lne) .and. (4==FEDB(num)%lnf)) then
      res = 'tet'
      call info('Element type: Tetrahedron lagrange P1')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .true.) .and. (8==FEDB(num)%lnn) .and. & ! Hexahedron Lagrange P1
        (8==FEDB(num)%lnv) .and. (12==FEDB(num)%lne) .and. (6==FEDB(num)%lnf)) then
      res = 'hex'
      call info('Element type: Hexahedron lagrange P1')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .false.) .and. (3==FEDB(num)%lnn) .and. & ! Edge Lagrange P2
        (2==FEDB(num)%lnv) .and. (1==FEDB(num)%lne) .and. (0==FEDB(num)%lnf)) then
      res = 'edg2'
      call info('Element type: Edge lagrange P2')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .false.) .and. (6==FEDB(num)%lnn) .and. & ! Triangle Lagrange P2
        (3==FEDB(num)%lnv) .and. (3==FEDB(num)%lne) .and. (0==FEDB(num)%lnf)) then
      res = 'tri2'
      call info('Element type: Triangle lagrange P2')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .false.) .and. (8==FEDB(num)%lnn) .and. & ! Quadrangle Lagrange P2
        (4==FEDB(num)%lnv) .and. (4==FEDB(num)%lne) .and. (0==FEDB(num)%lnf)) then
      res = 'quad2'
      call info('Element type: Quadrangle lagrange P2')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .false.) .and. (10==FEDB(num)%lnn) .and. & ! Tetrahedron Lagrange P2
        (4==FEDB(num)%lnv) .and. (6==FEDB(num)%lne) .and. (4==FEDB(num)%lnf)) then
      res = 'tet2'
      call info('Element type: Tetrahedron lagrange P2')
    elseif((FEDB(num)%nver_eq_nnod .eqv. .false.) .and. (20==FEDB(num)%lnn) .and. & ! Hexahedron Lagrange P2
        (8==FEDB(num)%lnv) .and. (12==FEDB(num)%lne) .and. (6==FEDB(num)%lnf)) then
      res = 'hex2'
      call info('Element type: Hexahedron lagrange P2')
    else
      call error('Finite element type not supported')
  endif


end function

subroutine mphtxt_node_ordering(el, tp)

  integer, dimension(:), intent(inout) :: el
  integer, intent(in) :: tp
  integer :: aux
  integer, dimension(:), allocatable :: auxel

    if (tp <= 0) then
      call error('module_read_mphtxt/node_ordering # Element type not supported')
    endif

    if ((FEDB(tp)%nver_eq_nnod .eqv. .true.) .and. & ! Nodes
        (FEDB(tp)%lnn == 1) .and. (FEDB(tp)%lnv == 1) .and. &
        (FEDB(tp)%lne == 0) .and. (FEDB(tp)%lnf == 0)) then
        ! PMH and MPHTXT uses the same node ordering in nodes

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .true.) .and. & ! Edge Lagrange P1
            (FEDB(tp)%lnn == 2) .and. (FEDB(tp)%lnv == 2) .and. &
            (FEDB(tp)%lne == 1) .and. (FEDB(tp)%lnf == 0)) then
        ! PMH and MPHTXT uses the same node ordering in edges lagrange P1

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .true.) .and. & ! Triangle Lagrange P1
            (FEDB(tp)%lnn == 3) .and. (FEDB(tp)%lnv == 3) .and. &
            (FEDB(tp)%lne == 3) .and. (FEDB(tp)%lnf == 0)) then
        ! PMH and MPHTXT uses the same node ordering in triangles lagrange P1

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .true.) .and. & ! Quadrangle Lagrange P1
            (FEDB(tp)%lnn == 4) .and. (FEDB(tp)%lnv == 4) .and. &
            (FEDB(tp)%lne == 4) .and. (FEDB(tp)%lnf == 0)) then
        ! PMH and MPHTXT don't have the same node ordering in quadrangles lagrange P1
        ! PMH[1,2,3,4] = MPH[1,2,4,3]
        if (size(el,1) /= FEDB(tp)%lnn) then
          call error('module_read_mphtxt/node_ordering # Wrong element size' )
        endif
        aux = el(4); el(4) = el(3); el(3) = aux

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .true.) .and. & ! Tetrahedron Lagrange P1
            (FEDB(tp)%lnn == 4) .and. (FEDB(tp)%lnv == 4) .and. &
            (FEDB(tp)%lne == 6) .and. (FEDB(tp)%lnf == 4)) then
        ! PMH and MPHTXT uses the same node ordering in tetrahedrons lagrange P1

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .true.) .and. & ! Hexahedron Lagrange P1
            (FEDB(tp)%lnn == 8) .and. (FEDB(tp)%lnv == 8) .and. &
            (FEDB(tp)%lne == 12) .and. (FEDB(tp)%lnf == 6)) then
        ! PMH and MPHTXT don't have the same node ordering in hexahedrons lagrange P1
        ! PMH[1,2,3,4,5,6,7,8] = MPH[1,2,4,3,5,6,8,7]
        if (size(el,1) /= FEDB(tp)%lnn) then
          call error('module_read_mphtxt/node_ordering # Wrong element size' )
        endif
        aux = el(4); el(4) = el(3); el(3) = aux
        aux = el(8); el(8) = el(7); el(7) = aux

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .false.) .and. & ! Edge Lagrange P2
            (FEDB(tp)%lnn == 3) .and. (FEDB(tp)%lnv == 2) .and. &
            (FEDB(tp)%lne == 1) .and. (FEDB(tp)%lnf == 0)) then
        ! PMH and MPHTXT uses the same node ordering in edges lagrange P2

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .false.) .and. & ! Triangle Lagrange P2
            (FEDB(tp)%lnn == 6) .and. (FEDB(tp)%lnv == 3) .and. &
            (FEDB(tp)%lne == 3) .and. (FEDB(tp)%lnf == 0)) then
        ! PMH and MPHTXT don't have the same node ordering in triangles lagrange P2
        ! PMH[1,2,3,4,5,6] = MPH[1,2,3,4,6,5]
        if (size(el,1) /= FEDB(tp)%lnn) then
          call error('module_read_mphtxt/node_ordering # Wrong element size' )
        endif
          aux = el(6); el(6) = el(5); el(5) = aux

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .false.) .and. & ! Quadragle Lagrange P2
            (FEDB(tp)%lnn == 9) .and. (FEDB(tp)%lnv == 4) .and. &
            (FEDB(tp)%lne == 4) .and. (FEDB(tp)%lnf == 0)) then
        ! PMH and MPHTXT uses the same node ordering in quadrangles lagrange P2

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .false.) .and. & ! Tetrahedron Lagrange P2
            (FEDB(tp)%lnn == 10) .and. (FEDB(tp)%lnv == 4) .and. &
            (FEDB(tp)%lne == 6) .and. (FEDB(tp)%lnf == 4)) then
        ! PMH and MPHTXT don't have the same node ordering in tetrahedrons lagrange P2
        ! PMH[1,2,3,4,5,6,7,8,9,10] = MPH[1,2,4,3,5,7,6,8,9,10]
        if (size(el,1) /= FEDB(tp)%lnn) then
          call error('module_read_mphtxt/node_ordering # Wrong element size' )
        endif
        aux = el(7); el(7) = el(6); el(6) = aux

    elseif ((FEDB(tp)%nver_eq_nnod .eqv. .false.) .and. & ! Hexahedron Lagrange P2
            (FEDB(tp)%lnn == 20) .and. (FEDB(tp)%lnv == 8) .and. &
            (FEDB(tp)%lne == 12) .and. (FEDB(tp)%lnf == 6)) then
        ! PMH and MPHTXT don't have the same node ordering in hexahedrons lagrange P2
        ! PMH[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27] =
        ! MPH[1,2,4,3,5,6,8,7,9,12,13,10,14,16,22,20,23,26,27,24,11,17,15,25,19,21,27]

        if (size(el,1) /= 27) then
          call error('module_read_mphtxt/node_ordering # Wrong element size' )
        endif

        if (allocated(auxel)) deallocate(auxel)
        allocate(auxel(size(el,1)))
        auxel(:) = el(:)

        el(1) = auxel(1); el(2) = auxel(2); el(3) = auxel(4); el(4) = auxel(3)
        el(5) = auxel(5); el(6) = auxel(6); el(7) = auxel(8); el(8) = auxel(7)
        el(9) = auxel(9); el(10) = auxel(12); el(11) = auxel(21); el(12) = auxel(10)
        el(13) = auxel(11); el(14) = auxel(13); el(15) = auxel(23); el(16) = auxel(14)
        el(17) = auxel(22); el(18) = auxel(27); el(19) = auxel(25); el(20) = auxel(16)
        el(21) = auxel(26); el(22) = auxel(15); el(23) = auxel(17); el(24) = auxel(20)
        el(25) = auxel(24); el(26) = auxel(18); el(27) = auxel(19)

    endif


end subroutine


end module