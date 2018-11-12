//
//  YAxisRenderer.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif

@objc(ChartYAxisRenderer)
open class YAxisRenderer: AxisRendererBase
{
    public init(viewPortHandler: ViewPortHandler?, yAxis: YAxis?, transformer: Transformer?)
    {
        super.init(viewPortHandler: viewPortHandler, transformer: transformer, axis: yAxis)
    }
    
    /// draws the y-axis labels to the screen
    open override func renderAxisLabels(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let viewPortHandler = self.viewPortHandler
            else { return }
        
        if !yAxis.isEnabled || !yAxis.isDrawLabelsEnabled
        {
            return
        }
        
        let xoffset = yAxis.xOffset
        let yoffset = yAxis.labelFont.lineHeight / 2.5 + yAxis.yOffset
        
        let dependency = yAxis.axisDependency
        let labelPosition = yAxis.labelPosition
        
        var xPos = CGFloat(0.0)
        
        var textAlign: NSTextAlignment
        
        if dependency == .left
        {
            if labelPosition == .outsideChart
            {
                textAlign = .right
                xPos = viewPortHandler.offsetLeft - xoffset
            }
            else
            {
                textAlign = .left
                xPos = viewPortHandler.offsetLeft + xoffset
            }
            
        }
        else
        {
            if labelPosition == .outsideChart
            {
                textAlign = .left
                xPos = viewPortHandler.contentRight + xoffset
            }
            else
            {
                textAlign = .right
                xPos = viewPortHandler.contentRight - xoffset
            }
        }
        
        drawYLabels(
            context: context,
            fixedPosition: xPos,
            positions: transformedPositions(),
            offset: yoffset - yAxis.labelFont.lineHeight,
            textAlign: textAlign)
    }
    
    open override func renderAxisLine(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let viewPortHandler = self.viewPortHandler
            else { return }
        
        if !yAxis.isEnabled || !yAxis.drawAxisLineEnabled
        {
            return
        }
        
        context.saveGState()
        
        context.setStrokeColor(yAxis.axisLineColor.cgColor)
        context.setLineWidth(yAxis.axisLineWidth)
        if yAxis.axisLineDashLengths != nil
        {
            context.setLineDash(phase: yAxis.axisLineDashPhase, lengths: yAxis.axisLineDashLengths)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        if yAxis.axisDependency == .left
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentBottom))
            context.strokePath()
        }
        else
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentBottom))
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
    /// draws the y-labels on the specified x-position
    internal func drawYLabels(
        context: CGContext,
        fixedPosition: CGFloat,
        positions: [CGPoint],
        offset: CGFloat,
        textAlign: NSTextAlignment)
    {
        guard
            let yAxis = self.axis as? YAxis
            else { return }
        
        let labelFont = yAxis.labelFont
        let labelTextColor = yAxis.labelTextColor
        
        let from = yAxis.isDrawBottomYLabelEntryEnabled ? 0 : 1
        let to = yAxis.isDrawTopYLabelEntryEnabled ? yAxis.entryCount : (yAxis.entryCount - 1)
        
        for i in stride(from: from, to: to, by: 1)
        {
            let text = yAxis.getFormattedLabel(i)
            
            ChartUtils.drawText(
                context: context,
                text: text,
                point: CGPoint(x: fixedPosition, y: positions[i].y + offset),
                align: textAlign,
                attributes: [NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelTextColor])
        }
    }
    
    open override func renderGridLines(context: CGContext)
    {
        guard let
            yAxis = self.axis as? YAxis
            else { return }
        
        if !yAxis.isEnabled
        {
            return
        }
        
        if yAxis.drawGridLinesEnabled
        {
            let positions = transformedPositions()
            
            context.saveGState()
            defer { context.restoreGState() }
            context.clip(to: self.gridClippingRect)
            
            context.setShouldAntialias(yAxis.gridAntialiasEnabled)
            context.setStrokeColor(yAxis.gridColor.cgColor)
            context.setLineWidth(yAxis.gridLineWidth)
            context.setLineCap(yAxis.gridLineCap)
            
            if yAxis.gridLineDashLengths != nil
            {
                context.setLineDash(phase: yAxis.gridLineDashPhase, lengths: yAxis.gridLineDashLengths)
                
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            // draw the grid
            for i in 0 ..< positions.count
            {
                drawGridLine(context: context, position: positions[i])
            }
        }

        if yAxis.drawZeroLineEnabled
        {
            // draw zero line
            drawZeroLine(context: context)
        }
    }
    
    open var gridClippingRect: CGRect
    {
        var contentRect = viewPortHandler?.contentRect ?? CGRect.zero
        let dy = self.axis?.gridLineWidth ?? 0.0
        contentRect.origin.y -= dy / 2.0
        contentRect.size.height += dy
        return contentRect
    }
    
    open func drawGridLine(
        context: CGContext,
        position: CGPoint)
    {
        guard
            let viewPortHandler = self.viewPortHandler
            else { return }
        
        context.beginPath()
        context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
        context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
        context.strokePath()
    }
    
    open func transformedPositions() -> [CGPoint]
    {
        guard
            let yAxis = self.axis as? YAxis,
            let transformer = self.transformer
            else { return [CGPoint]() }
        
        var positions = [CGPoint]()
        positions.reserveCapacity(yAxis.entryCount)
        
        let entries = yAxis.entries
        
        for i in stride(from: 0, to: yAxis.entryCount, by: 1)
        {
            positions.append(CGPoint(x: 0.0, y: entries[i]))
        }

        transformer.pointValuesToPixel(&positions)
        
        return positions
    }

    /// Draws the zero line at the specified position.
    open func drawZeroLine(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let viewPortHandler = self.viewPortHandler,
            let transformer = self.transformer,
            let zeroLineColor = yAxis.zeroLineColor
            else { return }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        var clippingRect = viewPortHandler.contentRect
        clippingRect.origin.y -= yAxis.zeroLineWidth / 2.0
        clippingRect.size.height += yAxis.zeroLineWidth
        context.clip(to: clippingRect)

        context.setStrokeColor(zeroLineColor.cgColor)
        context.setLineWidth(yAxis.zeroLineWidth)
        
        let pos = transformer.pixelForValues(x: 0.0, y: 0.0)
    
        if yAxis.zeroLineDashLengths != nil
        {
            context.setLineDash(phase: yAxis.zeroLineDashPhase, lengths: yAxis.zeroLineDashLengths!)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: pos.y))
        context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: pos.y))
        context.drawPath(using: CGPathDrawingMode.stroke)
    }
    
    open override func renderLimitLines(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let viewPortHandler = self.viewPortHandler,
            let transformer = self.transformer
            else { return }
        
        var limitLines = yAxis.limitLines
        
        if limitLines.count == 0
        {
            return
        }
        
        context.saveGState()
        
        let trans = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        for i in 0 ..< limitLines.count
        {
            let l = limitLines[i]
            
            if !l.isEnabled
            {
                continue
            }
            
            context.saveGState()
            defer { context.restoreGState() }
            
            //var clippingRect = viewPortHandler.contentRect
            //clippingRect.origin.y -= l.lineWidth / 2.0
            //clippingRect.size.height += l.lineWidth
            //context.clip(to: clippingRect)
            
            position.x = 0.0
            position.y = CGFloat(l.limit)
            position = position.applying(trans)
            
//            context.beginPath()
//            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
//            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
//            
//            context.setStrokeColor(l.lineColor.cgColor)
            context.setLineWidth(l.lineWidth)
//            if l.lineDashLengths != nil
//            {
//                context.setLineDash(phase: l.lineDashPhase, lengths: l.lineDashLengths!)
//            }
//            else
//            {
//                context.setLineDash(phase: 0.0, lengths: [])
//            }
//            
//            context.strokePath()
            
            context.beginPath()
            //context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y - (l.lineWidth + 2)))
            //context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y + (l.lineWidth + 2)))
            
            context.setFillColor(l.lineColor.cgColor)
            context.setStrokeColor(UIColor.white.cgColor)
            //context.setLineWidth(2)
            
            let rectWidth = viewPortHandler.contentRight - viewPortHandler.contentLeft
            //let rectHeight = position
            let rect = CGRect(x: viewPortHandler.contentLeft, y: position.y - (l.lineWidth + 2),
                width: rectWidth, height: l.lineWidth + 1)
            context.addRect(rect)
            
            context.drawPath(using: .fillStroke)
            
//            mLimitLinePaint.setColor(0xFFFFFFFF);
//            mLimitLinePaint.setStyle(Paint.Style.FILL);
//            c.drawRect(mViewPortHandler.contentLeft(), pts[1] - (l.getLineWidth() + 2),
//                       mViewPortHandler.contentRight(), pts[1] + (l.getLineWidth() + 2),
//                       mLimitLinePaint);
//            mLimitLinePaint.setStyle(Paint.Style.STROKE);
//            mLimitLinePaint.setColor(l.getLineColor());
            
            
            
            
            
            let label = l.label
            
            // if drawing the limit-value label is enabled
            if l.drawLabelEnabled && label.characters.count > 0
            {
                let labelLineHeight = l.valueFont.lineHeight
                
                let xOffset: CGFloat = 4.0 + l.xOffset
                let yOffset: CGFloat = l.lineWidth + labelLineHeight + l.yOffset
                
                if l.labelPosition == .rightTop
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentRight - xOffset,
                            y: position.y - yOffset),
                        align: .right,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
                else if l.labelPosition == .rightBottom
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentRight - xOffset,
                            y: position.y + yOffset - labelLineHeight),
                        align: .right,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
                else if l.labelPosition == .leftTop
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentLeft + xOffset,
                            y: position.y - yOffset),
                        align: .left,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
                else if l.labelPosition == .leftBox
                {
                    //                    float leftPos = mViewPortHandler.contentLeft() - 85;
                    //                    float topPos = pts[1] - 20;
                    //                    float bottomPos = topPos + 40;
                    //                    float rightPos = leftPos + 85;
                    //                    mLimitLinePaint.setColor(l.getLineColor());
                    //                    c.drawRoundRect(leftPos, topPos, rightPos, bottomPos,
                    //                                    4.0f, 4.0f, mLimitLinePaint);
                    //                    mLimitLinePaint.setColor(l.getTextColor());
                    //                    float xoffset = mYAxis.getXOffset();
                    //                    float xPos = mViewPortHandler.offsetLeft() - xoffset;
                    //                    mLimitLinePaint.setTextAlign(Align.RIGHT);
                    //                    c.drawText(label, xPos, topPos + 30, mLimitLinePaint);
                    
                    let leftPos = viewPortHandler.contentLeft - 29
                    let topPos = position.y - 9
                    let bottomPos = CGFloat(16.0)
                    let rightPos = CGFloat(36.0)
                    
                    context.beginPath()
                    context.setFillColor(l.lineColor.cgColor)
                    context.setStrokeColor(l.lineColor.cgColor)
                    context.setLineWidth(l.lineWidth)
                    let rect = CGRect(x: leftPos, y: topPos, width: rightPos, height: bottomPos)
                    
                    let clipPath: CGPath = UIBezierPath(roundedRect: rect, cornerRadius: 3.0).cgPath
                    context.addPath(clipPath)
                    context.closePath()
                    context.fillPath()
                    
                    
                    
                    //context.addRect(rect)
                    //context.drawPath(using: .fillStroke)
                    
                    ChartUtils.drawText(context: context,
                                        text: label,
                                        point: CGPoint(
                                            x: viewPortHandler.contentLeft - (xOffset - 10),
                                            y: topPos + 1),
                                        align: .right,
                                        attributes: [NSFontAttributeName: yAxis.labelFont, NSForegroundColorAttributeName: l.valueTextColor])
                    
                    
                }
                else if l.labelPosition == .rightBox
                {
                    let leftPos = viewPortHandler.contentRight
                    let topPos = position.y - 9
                    let bottomPos = CGFloat(16.0)
                    let rightPos = CGFloat(42.0)
                    
                    context.beginPath()
                    context.setFillColor(l.lineColor.cgColor)
                    context.setStrokeColor(l.lineColor.cgColor)
                    context.setLineWidth(l.lineWidth)
                    let rect = CGRect(x: leftPos, y: topPos, width: rightPos, height: bottomPos)
                    
                    let clipPath: CGPath = UIBezierPath(roundedRect: rect, cornerRadius: 3.0).cgPath
                    context.addPath(clipPath)
                    context.closePath()
                    context.fillPath()
                    
                    
                    
                    //context.addRect(rect)
                    //context.drawPath(using: .fillStroke)
                    
                    ChartUtils.drawText(context: context,
                                        text: label,
                                        point: CGPoint(
                                            x: viewPortHandler.contentRight + 5,
                                            y: topPos + 1),
                                        align: .left,
                                        attributes: [NSFontAttributeName: yAxis.labelFont, NSForegroundColorAttributeName: l.valueTextColor])
                    
                    
                }
                else
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentLeft + xOffset,
                            y: position.y + yOffset - labelLineHeight),
                        align: .left,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
            }
        }
        
        context.restoreGState()
    }
}
