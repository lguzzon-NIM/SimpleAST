
import strUtils
import simpleAST.strProcs

type
  SimpleASTNodeRef* = ref SimpleASTNodeObject
  SimpleASTNode* = SimpleASTNodeRef not nil
  SimpleASTNodeSeq* = seq[SimpleASTNode]
  SimpleASTNodeObject* = object
    FName: string
    FParent: SimpleASTNodeRef
    FParentIndex: Natural
    FChildren: SimpleASTNodeSeq


proc newSimpleASTNode* (aName: string = ""): SimpleASTNode {. inline .} =
  result = SimpleASTNode()
  result.FName = aName


proc name* (aSimpleASTNode: SimpleASTNode): string {. inline .} =
  result = aSimpleASTNode.FName


proc value* (aSimpleASTNode: SimpleASTNode): string {. inline .} =
  let lChildren = aSimpleASTNode.FChildren
  if  (lChildren.isNil or (lChildren.len == 0)):
    result = aSimpleASTNode.name
  else:
    result = ""
    for lChild in lChildren:
      result &= lChild.value


proc addChild* (aSimpleASTNode, aChild: SimpleASTNode): bool {. inline .} =
  result = aChild.FParent.isNil
  if result:
    if aSimpleASTNode.FChildren.isNil:
      aSimpleASTNode.FChildren = newSeqOfCap[SimpleASTNode](1)
    aChild.FParentIndex = aSimpleASTNode.FChildren.len
    aSimpleASTNode.FChildren.add(aChild)
    aChild.FParent = aSimpleASTNode


proc setValue* (aSimpleASTNode: SimpleASTNode, aValue: string): bool {. inline .} =
  result = (aSimpleASTNode.FChildren.isNil and aSimpleASTNode.addChild(newSimpleASTNode(aValue)))


proc parent* (aSimpleASTNode: SimpleASTNode): SimpleASTNodeRef {. inline .} =
  result = aSimpleASTNode.FParent


proc parentIndex* (aSimpleASTNode: SimpleASTNode): Natural {. inline .} =
  result = aSimpleASTNode.FParentIndex


proc children* (aSimpleASTNode: SimpleASTNode): SimpleASTNodeSeq {. inline .} =
  result = aSimpleASTNode.FChildren

const
  lcBackSlash = '\\'
  lcOpen = '('
  lcClose = ')'
  lcEscapeChars : set[char] = {lcOpen, lcClose}


proc asASTStr* (aSimpleASTNode: SimpleASTNode): string {. inline .} =
  result = aSimpleASTNode.name.strToEscapedStr(lcBackSlash, lcEscapeChars) & lcOpen
  for lChild in aSimpleASTNode.children:
    result &= lChild.asASTStr
  result &= lcClose


proc asSimpleASTNode* (aASTStr: string): SimpleASTNodeRef {. inline .} =
  var lIndex = 0
  var lStartIndex = lIndex
  var lASTRootNode: SimpleASTNodeRef
  let lLen = aASTStr.len
  while lIndex < lLen:
    case aASTStr[lIndex]
    of lcOpen:
      let lASTNode = newSimpleASTNode(aASTStr.substr(lStartIndex, <lIndex).escapedStrToStr(lcBackSlash))
      if (not lASTRootNode.isNil):
        let lAddChild = lASTRootNode.addChild(lASTNode)
        assert(lAddChild, "AddChild reurned false adding aNode")
      lASTRootNode = lASTNode
      lStartIndex = lIndex + 1
    of lcClose:
      if (not lASTRootNode.isNil):
        let lASTNode : SimpleASTNode = lASTRootNode
        if (not lASTNode.parent.isNil):
          lASTRootNode = lASTNode.parent
          lStartIndex = lIndex + 1
        else:
          if lIndex == <lLen:
            result = lASTNode
          break
      else:
        break
    of lcBackSlash:
      lIndex.inc
    else:
      discard
    lIndex.inc
