/// <reference types="react" />
import { TabProps } from './Tab';
export interface HorizontalOverflowPopperProps {
    /** Vertical direction of the popper. If enableFlip is set to true, this will set the initial direction before the popper flips. */
    direction?: 'up' | 'down';
    /** Horizontal position of the popper */
    position?: 'right' | 'left' | 'center' | 'start' | 'end';
    /** Custom width of the popper. If the value is "trigger", it will set the width to the select toggle's width */
    width?: string | 'trigger';
    /** Minimum width of the popper. If the value is "trigger", it will set the min width to the select toggle's width */
    minWidth?: string | 'trigger';
    /** Maximum width of the popper. If the value is "trigger", it will set the max width to the select toggle's width */
    maxWidth?: string | 'trigger';
    /** Enable to flip the popper when it reaches the boundary */
    enableFlip?: boolean;
    /** The container to append the select to. Defaults to document.body.
     * If your select is being cut off you can append it to an element higher up the DOM tree.
     * Some examples:
     * appendTo="inline"
     * appendTo={() => document.body}
     * appendTo={document.getElementById('target')}
     */
    appendTo?: HTMLElement | (() => HTMLElement) | 'inline';
    /** Flag to prevent the popper from overflowing its container and becoming partially obscured. */
    preventOverflow?: boolean;
}
export interface OverflowTabProps extends React.HTMLProps<HTMLLIElement> {
    /** Additional classes added to the overflow tab */
    className?: string;
    /** The tabs that should be displayed in the menu */
    overflowingTabs?: TabProps[];
    /** Flag which shows the count of overflowing tabs when enabled */
    showTabCount?: boolean;
    /** The text which displays when an overflowing tab isn't selected */
    defaultTitleText?: string;
    /** The aria label applied to the button which toggles the tab overflow menu */
    toggleAriaLabel?: string;
    /** z-index of the overflow tab */
    zIndex?: number;
    /** Flag indicating if scroll on focus of the first menu item should occur. */
    shouldPreventScrollOnItemFocus?: boolean;
    /** Time in ms to wait before firing the toggles' focus event. Defaults to 0 */
    focusTimeoutDelay?: number;
    /** Additional props to spread to the popper menu. */
    popperProps?: HorizontalOverflowPopperProps;
}
export declare const OverflowTab: React.FunctionComponent<OverflowTabProps>;
//# sourceMappingURL=OverflowTab.d.ts.map