from dataclasses import dataclass
from typing import List
from pyskiplist.skiplist import dumpNodes, SkipList, SkiplistNode  # pyskiplist enhancements in djbpitt fork
import pprint  # for debugging

pp = pprint.PrettyPrinter(indent=2)


# Dataclasses, variables, and functions for SVG visualization of skiplist
# Input parameters are in camelCase because Python doesn't allow hyphens in variable names

@dataclass
class SVGRect:
    x: float
    y: float
    height: float
    width: float
    stroke: str
    strokeWidth: float
    fill: str

    def __str__(self):
        return f'<rect x="{self.x}" y="{self.y}" height="{self.height}" width="{self.width}" \
        stroke="{self.stroke}" stroke-width="{self.strokeWidth}" fill="{self.fill}"/>'


@dataclass
class SVGCircle:
    cx: float
    cy: float
    r: float
    fill: str

    def __str__(self):
        return f'<circle cx="{self.cx}" cy="{self.cy}" r="{self.r}" fill="{self.fill}"/>'


@dataclass
class SVGText:
    x: float
    y: float
    dominantBaseline: str
    textAnchor: str
    fill: str
    fontSize: str
    content: str
    dy: float = None

    def __str__(self):
        _dyRep = f'dy="{self.dy}"' if self.dy else ''
        return f'<text x="{self.x}" y="{self.y}" {_dyRep} dominant-baseline="{self.dominantBaseline}" \
        text-anchor="{self.textAnchor}" fill="{self.fill}" font-size="{self.fontSize}">{self.content}</text>'


@dataclass
class SVGLine:
    x1: float
    y1: float
    x2: float
    y2: float
    stroke: str
    strokeWidth: float
    markerEnd: str

    def __str__(self):
        return f'<line x1="{self.x1}" y1="{self.y1}" x2="{self.x2}" y2="{self.y2}" stroke="{self.stroke}" \
        stroke-width="{self.strokeWidth}" marker-end="{self.markerEnd}"/>'


def SVGStartTag(x: float, y: float, width: float, height: float) -> str:
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x} {y} {width} {height}" height="{height + 100}">'


defs = '''
<defs>
  <marker id="arrowend"
          viewBox="-30 -8 30 16"
          markerWidth="30"
          markerHeight="8">
     <path d="M -30 0  L -30 8  L 0 0  L -30 -8  Z" fill="black"/>
 </marker>
</defs>
'''

# sample data
sl = SkipList()
sl_tokens = "the red and the black cat played with the gray and the brown koalas".split()
for index, token in enumerate(sl_tokens):
    sl.insert(str(index).zfill(4), token)
pp.pprint(dumpNodes(sl))

# SVG constants
SkiplistNodes = dumpNodes(sl)  # node 0 is head, data begins at node 1
boxSize = 100
boxSpacing = boxSize * 2
boxCenterOffset = boxSize / 2
textShift = 3  # @dy value to center text vertically in rectangle
textSize = '400%'
dataNodes = [x for x in SkiplistNodes if not x.name]
maxLevels = max(map(lambda x: x.level, dataNodes))
nodeCount = len(SkiplistNodes)
dataNodeCount = len(dataNodes)
circleRadius = boxSize * .1
nilColor = '#E8E8E8'


def computeOffsetsOfNodesAtLevel(nodes: List[SkiplistNode], nodeCount: int, level: int) -> List:
    """Filter to keep all nodes at specified level or higher

    Incorporate head and tail
    """
    _offsets = [0]
    for _offset, _node in enumerate(nodes):
        if _node.level >= level and not _node.name:
            _offsets.append(_offset)
    _offsets.append(nodeCount - 1)  # offset of tail
    return _offsets


# construct SVG
SVGElements = [SVGStartTag(x=-boxSpacing,
                           y=-(maxLevels + 1) * boxSize,
                           width=boxSpacing * (nodeCount + 5),
                           height=(maxLevels + 2) * boxSize), defs]
# start tag
# arrowhead
# nodes
for offset, node in enumerate(SkiplistNodes):
    if node.name == 'head':
        for level in range(1, maxLevels + 1):  # rectangles
            SVGElements.append(SVGRect(x=offset * boxSpacing,
                                       y=-level * boxSize,
                                       width=boxSize,
                                       height=boxSize,
                                       stroke='black',
                                       strokeWidth=2,
                                       fill='none'))
            SVGElements.append(SVGCircle(cx=offset * boxSpacing + boxCenterOffset,
                                         cy=-level * boxSize + boxCenterOffset,
                                         r=circleRadius,
                                         fill='black'))
        SVGElements.append(SVGText(x=offset * boxSpacing + boxCenterOffset,
                                   y=150,
                                   dominantBaseline='middle',
                                   textAnchor='middle',
                                   fill='gray',
                                   fontSize=textSize,
                                   content='[head]'))
    elif node.name == 'tail':
        for level in range(1, maxLevels + 1):  # rectangles
            SVGElements.append(SVGRect(x=offset * boxSpacing,
                                       y=-level * boxSize, width=boxSize,
                                       height=boxSize,
                                       stroke='black',
                                       strokeWidth=2,
                                       fill=nilColor))
            SVGElements.append(SVGText(x=offset * boxSpacing + boxCenterOffset,
                                       y=-(level * boxSize) + boxCenterOffset,
                                       dominantBaseline='middle',
                                       textAnchor='middle',
                                       fill='black',
                                       fontSize='300%',
                                       content='NIL'))
        SVGElements.append(SVGText(x=offset * boxSpacing + boxCenterOffset,
                                   y=150, dominantBaseline='middle',
                                   textAnchor='middle',
                                   fill='gray',
                                   fontSize=textSize,
                                   content='[tail]'))
    else:  # regular node
        # create numbered yellow box for node, with value underneath
        SVGElements.append(SVGRect(x=offset * boxSpacing,
                                   y=0,
                                   height=boxSize,
                                   width=boxSize,
                                   stroke='black',
                                   strokeWidth=2,
                                   fill='yellow'))
        SVGElements.append(SVGText(x=offset * boxSpacing + boxCenterOffset,
                                   y=boxCenterOffset,
                                   dy=textShift,
                                   dominantBaseline='middle',
                                   textAnchor='middle',
                                   fill='black',
                                   fontSize=textSize,
                                   content=str(offset)))
        SVGElements.append(SVGText(x=offset * boxSpacing + boxCenterOffset,
                                   y=150,
                                   textAnchor='middle',
                                   dominantBaseline='middle',
                                   fill='black',
                                   fontSize=textSize,
                                   content=node.value))
        # create dotted boxes for all levels
        for level in range(1, node.level + 1):
            SVGElements.append(SVGRect(x=offset * boxSpacing,
                                       y=-level * boxSize,
                                       height=boxSize,
                                       width=boxSize,
                                       stroke='black',
                                       strokeWidth=2,
                                       fill='none'))
            SVGElements.append(
                SVGCircle(cx=offset * boxSpacing + boxCenterOffset,
                          cy=-level * boxSize + boxCenterOffset,
                          r=circleRadius,
                          fill='black'))
# draw arrows for levels
for currentLevel in range(1, maxLevels + 1):
    offsetsOfNodesToLink = computeOffsetsOfNodesAtLevel(SkiplistNodes, nodeCount, currentLevel)
    for sourceOffset, targetOffset in zip(offsetsOfNodesToLink, offsetsOfNodesToLink[1:]):
        height = -currentLevel * boxSize + boxCenterOffset
        SVGElements.append(SVGLine(x1=sourceOffset * boxSpacing + boxCenterOffset,
                                   y1=height,
                                   x2=targetOffset * boxSpacing,
                                   y2=height,
                                   stroke='black',
                                   strokeWidth=2,
                                   markerEnd='url(#arrowend)'))
SVGElements.append('</svg>')
SVGString = ("\n".join([str(x) for x in SVGElements]))
print(SVGString)
